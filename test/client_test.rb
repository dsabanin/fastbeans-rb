class ClientTest < TestUnit::Unit::TestCase

  def setup
    @client = Fastbeans::Client.new
    @client.connection_class = MockConnection
  end

  def test_how_call_works
    real = @client.call("+", 1, 2, 3)
    assert_equal ["+", 1, 2, 3], real
  end

  def test_how_cached_call_works
    real1 = @client.cached_call("+", 1, 2, 3)
    real2 = @client.cached_call("+", 1, 2, 3)
    assert_equal real1.object_id, real2.object_id

    @client.clear_call_cache!

    real3 = @client.cached_call("+", 1, 2, 3)
    assert real1.object_id != real3.object_id
  end
end

