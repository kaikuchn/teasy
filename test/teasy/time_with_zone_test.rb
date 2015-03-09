require 'test_helper'

class TimeWithZoneTest < Minitest::Unit::TestCase
  def setup
    @time = Time.utc(2042, 1, 2, 12, 30, 45, 1.112)
    @dtime = @time.to_datetime
  end

  def teardown
  end

  def test_can_wrap_time
    assert_kind_of Teasy::TimeWithZone, Teasy::TimeWithZone.from_time(@time)
  end

  def test_can_wrap_datetime
    timestamptz = Teasy::TimeWithZone.from_datetime(@dtime)
    assert_kind_of Teasy::TimeWithZone, timestamptz
  end

  def test_from_time_preserves_zone
    assert_equal 'UTC', Teasy::TimeWithZone.from_time(@time).zone
  end

  def test_from_time_preserves_nsec_accuracy
    timestamptz = Teasy::TimeWithZone.from_time(@time)
    assert_equal @time.to_i, timestamptz.to_i
    assert_equal 1112, timestamptz.nsec
  end

  def test_from_datetime_has_no_zone
    timestamptz = Teasy::TimeWithZone.from_datetime(@dtime)
    assert_nil timestamptz.zone
  end

  def test_from_datetime_preserves_nsec_accuracy
    timestamptz = Teasy::TimeWithZone.from_datetime(@dtime)
    assert_equal @time.to_i, timestamptz.to_i
    assert_equal 1112, timestamptz.nsec
  end
end
