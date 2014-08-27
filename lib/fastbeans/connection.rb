require 'socket'
require 'fastbeans/request'

module Fastbeans
  class Connection
    MAX_RETRIES=3

    attr_reader :socket

    def initialize(host, port)
      Fastbeans.debug("Connecting to #{host}:#{port}")
      @host, @port = host, port
      begin
        @socket = connect!(@host, @port)
      rescue => e 
        Fastbeans.error(e)
        raise RemoteConnectionDead, e.message
      end
    end

    def connect!(host, port)
      @socket = TCPSocket.new(host, port)
      @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      @socket
    end

    def get_socket
      @socket || connect!(@host, @port)
    end

    def disconnect!
      if @socket
        @socket.close rescue nil
        @socket = nil
      end
    end

    def reconnect!
      disconnect!
      connect!(@host, @port)
    end

    def call(*data)
      retries = 0
      begin
        call_without_retries(data)
      rescue Fastbeans::RemoteConnectionFailed, Fastbeans::ResponseReadTimeout => e
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

    def call_without_retries(data)
      perform(data)

    rescue IOError, Errno::EPIPE, Errno::ECONNREFUSED, Errno::ECONNRESET, MessagePack::MalformedFormatError => e
      disconnect!
      ne = RemoteConnectionFailed.new(e.message)
      ne.orig_exc = e
      raise ne

    rescue Exception
      disconnect!
      raise
    end

    def with_socket
      yield(get_socket)
    rescue Exception => anything
      disconnect!
      raise
    end

    def perform(data)
      Request.new(self).perform(data)
    end
  end
end
