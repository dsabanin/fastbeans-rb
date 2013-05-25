require 'msgpack'
require 'thread'
require 'rufus-lru'

module Fastbeans

  class Client
    CALL_CACHE_SIZE=100
    MAX_RETRIES=3
    
    attr_reader :call_cache

    def initialize(host="127.0.0.1", port=12345, cache_size=nil)
      @host, @port = host, port
      @cache_size ||= CALL_CACHE_SIZE
      @call_cache = Rufus::Lru::SynchronizedHash.new(@cache_size)
      connect!(host, port)
    end

    def clear_call_cache!
      @call_cache.clear
    end

    def reconnect!
      disconnect!
      connect!(@host, @port)
    end


    def connect!(host, port)
      Fastbeans.debug("Connecting to #{host}:#{port}")
      @sock = TCPSocket.new(host, port)
      @sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      @mutex = Mutex.new
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
      resp = @mutex.synchronize do
        payload = MessagePack.pack(data).force_encoding("BINARY")
        @sock.write([payload.bytesize].pack("N"))
        @sock.write(payload)
        MessagePack.load(@sock)
      end
      if resp == 0xDEAD
        raise RemoteException.new("Remote exception on #{data.inspect} through #{@sock.inspect}")
      else
        resp
      end
    rescue IOError, Errno::EPIPE => e
      ne = RemoteConnectionFailed.new(e.message)
      ne.orig_exc = e
      raise ne
    end

    def disconnect!
      if @sock
        @sock.close rescue nil
      end
    end
  end

end
