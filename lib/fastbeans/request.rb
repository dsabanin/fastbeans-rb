require 'digest/md5'
require 'fastbeans/response'

module Fastbeans
  class Request
    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def sign(data)
      Digest::MD5.hexdigest(data.inspect)
    end

    def perform(data)
      signature = sign(data)
      signed_data = [signature, data]
      payload = MessagePack.pack(signed_data)
      if payload.respond_to?(:force_encoding)
        payload = payload.force_encoding('BINARY')
      end
      connection.with_socket do |sock|
        sock.write([payload.bytesize].pack("N"))
        sock.write(payload)
        raw_resp = MessagePack.load(sock)
        resp = Response.new(data, raw_resp)
        if resp.signed_with?(signature)
          resp.payload
        else
          raise ResponseSignatureMismatch, "Received #{resp.signature} signature instead of expected #{signature} for #{data} call"
        end
      end
    end
  end
end
