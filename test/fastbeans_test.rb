class FastbeansTest < MiniTest::Unit::TestCase

  def test_should_autocreate_exceptions
    assert_equal Fastbeans::RemoteException, Fastbeans.exception('RemoteException')
    assert_equal 'Fastbeans::SomeException', Fastbeans.exception('SomeException').to_s
  end
end
