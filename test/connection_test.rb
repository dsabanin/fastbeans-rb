require_relative 'test_helper'

class ConnectionTest < MiniTest::Unit::TestCase

  def setup
    Fastbeans::Connection.any_instance.stubs(:connect!).returns(StringIO.new)
    @conn = Fastbeans::Connection.new('localhost', 12345)
    @test_msg = ['+', 1, 2, 3]
  end

  def test_socket_presence
    assert_is_a_socket @conn.socket
  end

  def test_disconnect
    @conn.disconnect!
    assert_nil @conn.socket
  end

  def test_get_socket
    assert_is_a_socket @conn.get_socket

    @conn.disconnect!

    assert_is_a_socket @conn.get_socket
  end

  def test_reconnect
    @conn.expects(:disconnect!)
    @conn.expects(:connect!).with('localhost', 12345)
    @conn.reconnect!
  end

  def test_with_socket
    @conn.with_socket do |sock|
      assert_is_a_socket sock
    end
  end

  def test_call_without_retries
    Fastbeans::Request.any_instance.expects(:perform).with(@test_msg).returns(:reply)
    assert_equal :reply, @conn.call_without_retries(@test_msg)
  end

  def test_exception_during_call
    @conn.expects(:perform).with(@test_msg).raises(RuntimeError)
    @conn.expects(:disconnect!)
    assert_raises RuntimeError do
      @conn.call_without_retries(@test_msg)
    end
  end

  def test_io_exceptions_during_call
    ioexcs = [IOError, Errno::EPIPE, MessagePack::MalformedFormatError]
    ioexcs.each do |exc|
      @conn.expects(:perform).with(@test_msg).raises(exc)
      @conn.expects(:disconnect!)
      assert_raises Fastbeans::RemoteConnectionFailed do
        @conn.call_without_retries(@test_msg)
      end
    end
  end

  def test_perform
    req = mock
    req.expects(:perform).with(@test_msg).returns(:result)
    Fastbeans::Request.expects(:new).with(@conn).returns(req)
    assert_equal :result, @conn.perform(@test_msg)
  end

  def test_call_with_retries
    @conn.expects(:call_without_retries).
        with(@test_msg).times(4).
        raises(Fastbeans::RemoteConnectionFailed)
    @conn.expects(:reconnect!).times(3)
    assert_raises Fastbeans::RemoteConnectionDead do
      assert_nil @conn.call(*@test_msg)
    end
  end

  def assert_is_a_socket(sock)
    assert_instance_of StringIO, sock
  end

end
