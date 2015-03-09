require 'test_helper'

class TimeWithZoneTest < Minitest::Unit::TestCase
  def setup
    @params = [2042, 4, 2, 8, 30, 45, 1_112]
    @timestamptz = TimeWithZone.new(*@params)
  end

  def test_constructor_parameter
    assert_equal 2042, @timestamptz.year
    assert_equal 4, @timestamptz.month
    assert_equal 2, @timestamptz.day
    assert_equal 8, @timestamptz.hour
    assert_equal 30, @timestamptz.min
    assert_equal 45, @timestamptz.sec
    assert_equal 1_112, @timestamptz.nsec
  end

  def test_constructor_defaults_to_utc
    assert_true @timestamptz.utc?
    assert_equal 'UTC', @timestamptz.zone
  end

  def test_constructor_applies_provided_timezone
    timestamptz = TimeWithZone.new(*@params, 'Europe/Berlin')
    assert_equal 'Europe/Berlin', timestamptz.zone
    assert_false timestamptz.utc?
    assert_true timestamptz.dst?
    assert_equal 7200, timestamptz.offset
    assert_equal @timestamptz + 7200, timestamptz
  end
end
