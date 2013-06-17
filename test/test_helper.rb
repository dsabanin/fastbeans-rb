if RUBY_VERSION !~ /^1.8/
  # require 'minitest/unit'
  require 'minitest/autorun'
  require 'minitest/pride'
  TestUnit = Minitest
else
  require 'test/unit'
end
require 'mocha/setup'

require 'fastbeans'

class MockConnection
  def initialize(*any); end

  def call(*data)
    data
  end

  attr_accessor :socket

  def with_socket
    yield(socket)
  end
end
