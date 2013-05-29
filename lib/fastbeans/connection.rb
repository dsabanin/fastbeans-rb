require 'socket'

module Fastbeans
  class Connection
    attr_reader :socket

    def initialize(host, port)
      Fastbeans.debug("Connecting to #{host}:#{port}")
      @host, @port = host, port
      connect!(@host, @port)
    end

    def connect!(host, port)
      @socket = TCPSocket.new(host, port)
      @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
    end

    def disconnect!
      if @socket
        @socket.close rescue nil
      end
    end

    def reconnect!
      disconnect!
      connect!(@host, @port)
    end

    def write(buf)
      @socket.write(buf)
    end
  end
end
