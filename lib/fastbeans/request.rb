require 'digest/md5'
require 'fastbeans/response'

module Fastbeans
  class Request
    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def sign(call_data)
      Digest::MD5.hexdigest(call_data.inspect)
    end

    def build_payload(call_data)
      signature = sign(call_data)
      signed_data = [signature, call_data]
      payload = MessagePack.pack(signed_data)
      if payload.respond_to?(:force_encoding)
        payload.force_encoding('BINARY')
      end
      [signature, payload]
    end

    def write_payload(sock, payload)
      sock.write([payload.bytesize].pack('N'))
      sock.write(payload)
    end

    def read_response(sock, call_data)
      raw_resp = MessagePack.load(sock)
      Fastbeans::Response.new(call_data, raw_resp)
    end

    def perform(call_data)
      connection.with_socket do |sock|
        signature, payload = build_payload(call_data)
        write_payload(sock, payload)
        resp = read_response(sock, call_data)
        if resp.error? or resp.signed_with?(signature)
          resp.payload
        else
          raise ResponseSignatureMismatch, "Received #{resp.signature} signature instead of expected #{signature} for #{call_data} call"
        end
      end
    end
  end
end
