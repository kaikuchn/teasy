require_relative '../test_helper.rb'

class TimestampTest < Minitest::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_initializing_returns_an_instance
    assert_kind_of Teasy::Timestamp, Teasy::Timestamp.new
  end
end
