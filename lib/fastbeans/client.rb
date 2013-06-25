require 'msgpack'
require 'rufus-lru'
require 'connection_pool'
require 'fastbeans/connection'

module Fastbeans
  class Client
    CALL_CACHE_SIZE=100
    
    attr_reader :call_cache
    attr_accessor :connection_class
    attr_accessor :cache_class

    def initialize(host='127.0.0.1', port=12345, cache=nil, pool_opts={})
      @host, @port = host, port
      @call_cache = cache || Rufus::Lru::SynchronizedHash.new(CALL_CACHE_SIZE)
      @pool_opts =  {:size => 5, :timeout => 5}.update(pool_opts)
      @connection_class = Fastbeans::Connection
    end

    def pool
      @pool ||= ConnectionPool.new(@pool_opts) do
        @connection_class.new(@host, @port)
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
