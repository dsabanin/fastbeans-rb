require 'socket'

module Fastbeans
  class Connection
    MAX_RETRIES=3

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

    def call(*data)
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

    def call_without_retries(*data)
      payload = MessagePack.pack(data).force_encoding("BINARY")
      @socket.write([payload.bytesize].pack("N"))
      @socket.write(payload)
      raw_resp = MessagePack.load(@socket)
      resp = Response.new(data, raw_resp)
      resp.payload
    rescue IOError, Errno::EPIPE, MessagePack::MalformedFormatError => e
      ne = RemoteConnectionFailed.new(e.message)
      ne.orig_exc = e
      raise ne
    end

  end
end