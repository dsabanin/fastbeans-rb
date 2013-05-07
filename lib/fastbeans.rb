require "fastbeans/version"
require "fastbeans/errors"
require "fastbeans/client"

module Fastbeans
  class << self
    # Debug mode
    attr_accessor :debug_mode

    def debug(str_or_exc)
      case str_or_exc
        when String 
          STDERR.puts("[#{Time.now}] #{str}") if self.debug_mode
        when Exception
          debug("Exception: #{str_or_exc.message}\n#{str_or_exc.backtrace.join("\n")}")
      end
    end

    def benchmark(str, &blk)
      debug(str)
      t1 = Time.now
      blk.call
    ensure
      t2 = Time.now
      debug("Time spent: #{t2-t1}s")
    end
  end
end
