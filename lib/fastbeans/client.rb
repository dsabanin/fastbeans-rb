require 'msgpack'
require 'thread'

module Fastbeans

  class Client
    def initialize(host, port)
      @host, @port = host, port
      connect!(host, port)
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
