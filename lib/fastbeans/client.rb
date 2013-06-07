require 'msgpack'
require 'rufus-lru'
require 'fastbeans/connection'
require 'connection_pool'

module Fastbeans
  class Client
    CALL_CACHE_SIZE=100
    
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
        pool.with do |conn|
          conn.call(*data)
        end
      end
    end

    def cached_call(*data)
      @call_cache[data] ||= call(*data)
    end
  end
end
