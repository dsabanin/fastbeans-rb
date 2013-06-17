require 'minitest/unit'
require 'minitest/autorun'
begin; require 'minitest/pride'; rescue LoadError end
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
