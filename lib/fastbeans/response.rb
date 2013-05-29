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
      name = camelize(underscore(@raw_response["fastbeans-error"]))
      Fastbeans.exception(name).new(@raw_response["error-information"])
    end

    def camelize(term, uppercase_first_letter = true)
      string = term.to_s
      acronym_regex = /(?=a)b/
      if uppercase_first_letter
        string = string.sub(/^[a-z\d]*/) { $&.capitalize }
      else
        string = string.sub(/^(?:#{acronym_regex}(?=\b|[A-Z_])|\w)/) { $&.downcase }
      end
      string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
    end

    def underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      acronym_regex = /(?=a)b/
      word.gsub!(/::/, '/')
      word.gsub!(/(?:([A-Za-z\d])|^)(#{acronym_regex})(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end
  end

end
