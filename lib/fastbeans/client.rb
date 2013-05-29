require 'msgpack'
require 'rufus-lru'
require 'fastbeans/connection'
require 'fastbeans/response'
require 'connection_pool'

module Fastbeans
  class Client
    CALL_CACHE_SIZE=100
    MAX_RETRIES=3
    
    attr_reader :call_cache

    def initialize(host="127.0.0.1", port=12345, cache_size=nil, pool_opts={})
      @host, @port = host, port
      @cache_size ||= CALL_CACHE_SIZE
      @call_cache = Rufus::Lru::SynchronizedHash.new(@cache_size)
      @pool_opts =  {:size => 5, :timeout => 5}.update(pool_opts)
    end

    def pool
      @pool ||= ConnectionPool.new(@pool_opts) do
        Fastbeans::Connection.new(@host, @port)
      end
    end

    def clear_call_cache!
      @call_cache.clear
    end

    def call(*data)
      Fastbeans.benchmark("Calling: #{data.inspect}") do
        retries = 0
        begin
          call_without_retries(*data)
        rescue Fastbeans::RemoteConnectionFailed => e
          Fastbeans.debug(e)
          if retries < MAX_RETRIES
            Fastbeans.debug("Retrying (#{retries} out of #{MAX_RETRIES} retries)")
            retries += 1
            begin
              reconnect!
            rescue => e
              raise RemoteConnectionDead, e.message
            end
            retry
          else
            raise RemoteConnectionDead, "#{e.message} (#{retries} retries)"
          end
        end
      end
    end

    def cached_call(*data)
      @call_cache[data] ||= call(*data)
    end

    def call_without_retries(*data)
      raw_resp = pool.with do |conn|
        payload = MessagePack.pack(data).force_encoding("BINARY")
        conn.write([payload.bytesize].pack("N"))
        conn.write(payload)
        MessagePack.load(conn.socket)
      end
      resp = Response.new(data, raw_resp)
      resp.payload
    rescue IOError, Errno::EPIPE, MessagePack::MalformedFormatError => e
      ne = RemoteConnectionFailed.new(e.message)
      ne.orig_exc = e
      raise ne
    end
  end
end
