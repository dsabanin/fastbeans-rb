require 'msgpack'
require 'thread'
require 'rufus-lru'

module Fastbeans

  class Client
    CALL_CACHE_SIZE=100

    attr_reader :call_cache

    def initialize(host, port, cache_size=nil)
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
      @sock = TCPSocket.new(host, port)
      @sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      @mutex = Mutex.new
    end

    def call(*data)
      counter = 0
      begin
        call_without_retries(*data)
      rescue Fastbeans::RemoteConnectionFailed => e
        if counter < 3
          counter += 1
          begin
            reconnect!
          rescue => e
            raise RemoteConnectionDead, e.message
          end
          retry
        else
          raise RemoteConnectionDead, "#{e.message} (#{counter} retries)"
        end
      end
    end

    def cached_call(*data)
      @call_cache[data] ||= call(*data)
    end

    def call_without_retries(*data)
      resp = @mutex.synchronize do
        MessagePack.pack(data, @sock)
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
