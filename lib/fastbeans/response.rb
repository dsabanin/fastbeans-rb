module Fastbeans


  class Response

    def initialize(call_data, raw_response)
      @call_data = call_data
      @raw_response = raw_response
    end

    def error?
      @raw_response.is_a?(Hash) and @raw_response.has_key?("fastbeans-error")
    end

    def payload
      unless error?
        @raw_response
      else
        raise to_exception
      end
    end

    def to_exception
      name = @raw_response["fastbeans-error"].underscore.classify
      Fastbeans.exception(name).new(@raw_response["error-information"])
    end
  end

end
