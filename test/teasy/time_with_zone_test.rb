require 'test_helper'

class TimeWithZoneTest < Minitest::Test
  def setup
    @params = [2042, 4, 2, 0, 30, 45, 1.112]
    @timestamptz = Teasy::TimeWithZone.new(*@params)
    @timestamptz_berlin = Teasy::TimeWithZone.new(*@params, 'Europe/Berlin')
  end

  def test_constructor_parameter
    assert_equal 2042, @timestamptz.year
    assert_equal 4, @timestamptz.month
    assert_equal 2, @timestamptz.day
    assert_equal 0, @timestamptz.hour
    assert_equal 30, @timestamptz.min
    assert_equal 45, @timestamptz.sec
    assert_equal 1_112, @timestamptz.nsec
  end

  def test_from_time
    time = Time.utc(*@params)
    time_with_zone = Teasy::TimeWithZone.from_time(time)
    assert_instance_of Teasy::TimeWithZone, time_with_zone
    assert_equal 'UTC', time_with_zone.zone
    assert_equal 0, time_with_zone.hour
    time_with_zone = Teasy::TimeWithZone.from_time(time, 'Europe/Berlin')
    assert_equal 'Europe/Berlin', time_with_zone.zone
    assert_equal 0, time_with_zone.hour
  end

  def test_from_utc
    time = Time.utc(*@params)
    time_with_zone = Teasy::TimeWithZone.from_utc(time)
    assert_instance_of Teasy::TimeWithZone, time_with_zone
    assert_equal 'UTC', time_with_zone.zone
    assert_equal 0, time_with_zone.hour
    time_with_zone = Teasy::TimeWithZone.from_utc(time, 'Europe/Berlin')
    assert_equal 'Europe/Berlin', time_with_zone.zone
    assert_equal 2, time_with_zone.hour
    assert time_with_zone.dst?
  end

  def test_constructor_defaults_to_teasy_default_zone
    assert_equal Teasy.default_zone, @timestamptz.zone
    Teasy.stub(:default_zone, 'Europe/Berlin') do
      timestamptz = Teasy::TimeWithZone.new(*@params)
      assert_equal 'Europe/Berlin', timestamptz.zone
    end
  end

  def test_constructor_applies_provided_timezone
    assert_equal 'Europe/Berlin', @timestamptz_berlin.zone
  end

  def test_in_time_zone!
    time = @timestamptz.dup.in_time_zone!('America/Chicago')
    assert_instance_of Teasy::TimeWithZone, time
    assert_equal @timestamptz, time
    assert_equal 'America/Chicago', time.zone
    assert_equal '01T19:30:45', time.strftime('%dT%H:%M:%S')
    assert_equal(-18_000, time.utc_offset)
    assert_equal time.object_id, time.in_time_zone!('Europe/Berlin').object_id
  end

  def test_in_time_zone
    time = @timestamptz.in_time_zone('Asia/Calcutta')
    assert_instance_of Teasy::TimeWithZone, time
    assert_equal @timestamptz, time
    refute_equal time.object_id, @timestamptz.in_time_zone('Asia/Calcutta')
  end

  def test_raises_on_ambiguous_time
    dst_end = [2014, 10, 26, 2, 0, 0, 0, 'Europe/Berlin']
    assert_raises(TZInfo::AmbiguousTime) do
      Teasy::TimeWithZone.new(*dst_end)
    end
  end

  def test_raises_when_period_does_not_exist
    dst_start = [2014, 3, 30, 2, 30, 0, 0, 'Europe/Berlin']
    assert_raises(TZInfo::PeriodNotFound) do
      Teasy::TimeWithZone.new(*dst_start)
    end
  end

  def test_addition
    assert_equal 45, @timestamptz.sec
    @timestamptz += 5
    assert_equal 50, @timestamptz.sec
    assert_instance_of Teasy::TimeWithZone, @timestamptz
  end

  def test_addition_around_dst_end
    just_before_dst_end = [2014, 10, 26, 1, 59, 59, 0, 'Europe/Berlin']
    time = Teasy::TimeWithZone.new(*just_before_dst_end)
    assert((time + 3600).dst?)
    assert_equal('02:59:59 +0200', (time + 3600).strftime('%H:%M:%S %z'))
    refute((time + 3601).dst?)
    assert_equal('02:00:00 +0100', (time + 3601).strftime('%H:%M:%S %z'))
  end

  def test_addition_around_dst_start
    just_before_dst_start = [2014, 3, 30, 1, 59, 59, 0, 'Europe/Berlin']
    time = Teasy::TimeWithZone.new(*just_before_dst_start)
    refute time.dst?
    assert_equal('01:59:59 +0100', time.strftime('%H:%M:%S %z'))
    assert((time + 1).dst?)
    assert_equal('03:00:00 +0200', (time + 1).strftime('%H:%M:%S %z'))
  end

  def test_subtraction
    assert_equal 45, @timestamptz.sec
    @timestamptz -= 5
    assert_equal 40, @timestamptz.sec
    assert_instance_of Teasy::TimeWithZone, @timestamptz
    assert_instance_of Float, @timestamptz - @timestamptz
    assert_equal 5.0, @timestamptz - (@timestamptz - 5)
  end

  def test_subtraction_around_dst_end
    just_after_dst_end = [2014, 10, 26, 3, 0, 0, 0, 'Europe/Berlin']
    time = Teasy::TimeWithZone.new(*just_after_dst_end)
    refute time.dst?
    refute((time - 3600).dst?)
    assert_equal('02:00:00 +0100', (time - 3600).strftime('%H:%M:%S %z'))
    assert((time - 3601).dst?)
    assert_equal('02:59:59 +0200', (time - 3601).strftime('%H:%M:%S %z'))
  end

  def test_subtraction_around_dst_start
    just_after_dst_start = [2014, 3, 30, 3, 0, 0, 0, 'Europe/Berlin']
    time = Teasy::TimeWithZone.new(*just_after_dst_start)
    assert time.dst?
    assert_equal('03:00:00 +0200', time.strftime('%H:%M:%S %z'))
    refute((time - 1).dst?)
    assert_equal('01:59:59 +0100', (time - 1).strftime('%H:%M:%S %z'))
  end

  def test_comparison
    assert_operator @timestamptz, :>, @timestamptz_berlin
    assert_operator @timestamptz, :>=, @timestamptz_berlin
    assert_operator @timestamptz_berlin, :<, @timestamptz
    assert_operator @timestamptz_berlin, :<=, @timestamptz
    assert_operator @timestamptz, :==, @timestamptz
    @timestamptz_berlin += 7200
    assert_operator @timestamptz, :==, @timestamptz_berlin
  end

  def test_asctime
    assert_equal 'Wed Apr  2 00:30:45 2042', @timestamptz.asctime
    assert_equal 'Wed Apr  2 00:30:45 2042', @timestamptz_berlin.asctime
  end

  def test_ctime
    assert_equal 'Wed Apr  2 00:30:45 2042', @timestamptz.ctime
    assert_equal 'Wed Apr  2 00:30:45 2042', @timestamptz_berlin.ctime
  end

  def test_day
    assert_equal 2, @timestamptz.day
    assert_equal 2, @timestamptz.mday
    assert_equal 2, @timestamptz_berlin.day
    assert_equal 2, @timestamptz_berlin.mday
  end

  def test_dst?
    assert_equal false, @timestamptz.dst?
    assert_equal true, @timestamptz_berlin.dst?
    assert_equal false, (@timestamptz_berlin - 2_592_000).dst?
  end

  def test_eql?
    assert @timestamptz.eql?(@timestamptz)
    assert @timestamptz.eql?(@timestamptz_berlin + 7200)
    refute @timestamptz.eql?(@timestamptz.to_time)
  end

  def test_friday?
    friday = Teasy::TimeWithZone.new(2042, 04, 04)
    friday_berlin = Teasy::TimeWithZone.new(
      2042, 04, 04, 0, 0, 0, 0, 'Europe/Berlin')
    assert_equal true, friday.friday?
    assert_equal true, friday_berlin.friday?
    assert_equal false, @timestamptz.friday?
    assert_equal false, @timestamptz_berlin.friday?
  end

  def test_hash
    refute_equal @timestamptz.hash, @timestamptz_berlin.hash
    assert_equal @timestamptz.hash, @timestamptz.dup.hash
    assert_equal @timestamptz_berlin.hash, @timestamptz_berlin.utc.hash
    assert_equal @timestamptz.hash, (@timestamptz_berlin + 7200).hash
    refute_equal @timestamptz.hash, @timestamptz.to_time.hash
  end

  def test_hour
    assert_equal 0, @timestamptz.hour
    assert_equal 0, @timestamptz_berlin.hour
    assert_equal 22, @timestamptz_berlin.utc.hour
  end

  def test_inspect
    assert_equal '2042-04-02 00:30:45 UTC', @timestamptz.inspect
    assert_equal '2042-04-02 00:30:45 +0200', @timestamptz_berlin.inspect
    timestamptz = Teasy.stub(:default_zone, 'Europe/Berlin') do
      Teasy::TimeWithZone.new(2042)
    end
    assert_equal '2042-01-01 00:00:00 +0100', timestamptz.inspect
  end

  def test_min
    assert_equal 30, @timestamptz.min
    assert_equal 31, (@timestamptz_berlin + 60).min
  end

  def test_month
    assert_equal 4, @timestamptz.month
    assert_equal 3, (@timestamptz_berlin - 100_000).month
  end

  def test_mon
    assert_equal 4, @timestamptz.mon
    assert_equal 3, (@timestamptz_berlin - 100_000).mon
  end

  def test_monday?
    monday = Teasy::TimeWithZone.new(2042, 03, 31)
    monday_berlin = Teasy::TimeWithZone.new(
      2042, 03, 31, 0, 0, 0, 0, 'Europe/Berlin')
    assert_equal true, monday.monday?
    assert_equal true, monday_berlin.monday?
    assert_equal false, @timestamptz.monday?
    assert_equal false, @timestamptz_berlin.monday?
  end

  def test_nsec
    assert_equal 1_112, @timestamptz.nsec
    assert_equal 1_112, @timestamptz_berlin.nsec
  end

  def test_round
    assert_instance_of Teasy::TimeWithZone, @timestamptz.round
    assert_instance_of Teasy::TimeWithZone, @timestamptz_berlin.round(2)
    assert_equal 1_112, @timestamptz.nsec
    assert_equal 0, @timestamptz.round.nsec
    assert_equal 1_100, @timestamptz.round(7).nsec
    assert_equal 1_112, @timestamptz.round(9).nsec
  end

  def test_round!
    assert_equal 1_112, @timestamptz.nsec
    assert_equal 1_112, @timestamptz.round!(9).nsec
    assert_equal 1_110, @timestamptz.round!(8).nsec
    assert_equal 1_100, @timestamptz.round!(7).nsec
    assert_equal 1_000, @timestamptz.round!(6).nsec
    assert_equal 0, @timestamptz.round!.nsec
    assert_instance_of Teasy::TimeWithZone, @timestamptz.round!
    assert_instance_of Teasy::TimeWithZone, @timestamptz_berlin.round!(2)
    assert_equal @timestamptz.object_id, @timestamptz.round!.object_id
  end

  def test_saturday?
    saturday = Teasy::TimeWithZone.new(2042, 4, 5)
    saturday_berlin = Teasy::TimeWithZone.new(
      2042, 4, 5, 0, 0, 0, 0, 'Europe/Berlin')
    assert_equal true, saturday.saturday?
    assert_equal true, saturday_berlin.saturday?
    assert_equal false, @timestamptz.saturday?
    assert_equal false, @timestamptz_berlin.saturday?
  end

  def test_sec
    assert_equal 45, @timestamptz.sec
    assert_equal 45, @timestamptz_berlin.sec
    assert_equal 50, (@timestamptz_berlin + 5).sec
  end

  def test_strftime
    assert_equal '00 UTC', @timestamptz.strftime('%H %Z')
    assert_equal '00 +0000', @timestamptz.strftime('%H %z')
    assert_equal '00 CEST', @timestamptz_berlin.strftime('%H %Z')
    assert_equal '00 +0200', @timestamptz_berlin.strftime('%H %z')
  end

  def test_subsec
    assert_equal 1.112.to_r / 1_000_000, @timestamptz.subsec
    assert_equal 1.112.to_r / 1_000_000, @timestamptz_berlin.subsec
  end

  def test_sunday?
    sunday = Teasy::TimeWithZone.new(2042, 4, 6)
    sunday_berlin = Teasy::TimeWithZone.new(
      2042, 4, 6, 0, 0, 0, 0, 'Europe/Berlin')
    assert_equal true, sunday.sunday?
    assert_equal true, sunday_berlin.sunday?
    assert_equal false, @timestamptz.sunday?
    assert_equal false, @timestamptz_berlin.sunday?
  end

  def test_thursday?
    thursday = Teasy::TimeWithZone.new(2042, 4, 3)
    thursday_berlin = Teasy::TimeWithZone.new(
      2042, 4, 3, 0, 0, 0, 0, 'Europe/Berlin')
    assert_equal true, thursday.thursday?
    assert_equal true, thursday_berlin.thursday?
    assert_equal false, @timestamptz.thursday?
    assert_equal false, @timestamptz_berlin.thursday?
  end

  def test_to_a
    assert_equal [45, 30, 0, 2, 4, 2042, 3, 92, false, 'UTC'], @timestamptz.to_a
    berlin_to_a = @timestamptz_berlin.to_a
    assert_equal [45, 30, 0, 2, 4, 2042, 3, 92, true, 'CEST'], berlin_to_a
  end

  def test_to_time
    assert_instance_of Time, @timestamptz.to_time
    assert_equal 0, @timestamptz.to_time.utc_offset
    assert @timestamptz.to_time.utc?
    assert_equal @timestamptz, @timestamptz.to_time

    assert_equal 7200, @timestamptz_berlin.to_time.utc_offset
    assert_equal @timestamptz_berlin, @timestamptz_berlin.to_time
  end

  def test_to_datetime
    assert_instance_of DateTime, @timestamptz.to_datetime
    assert_equal 0, @timestamptz.to_datetime.offset
    assert_equal @timestamptz, @timestamptz.to_datetime

    assert_equal Rational(2, 24), @timestamptz_berlin.to_datetime.offset
    assert_equal @timestamptz_berlin, @timestamptz_berlin.to_datetime
  end

  def test_to_date
    assert_instance_of Date, @timestamptz.to_date
    assert_equal @timestamptz.day, @timestamptz.to_date.day
    assert_equal @timestamptz_berlin.day, @timestamptz_berlin.to_date.day
  end

  def test_to_f
    assert_instance_of Float, @timestamptz.to_f
    assert_in_epsilon 2_280_011_445.000_001, @timestamptz.to_f
    assert_in_epsilon 2_280_004_245.000_001, @timestamptz_berlin.to_f
  end

  def test_to_i
    assert_instance_of Fixnum, @timestamptz.to_i
    assert_equal 2_280_011_445, @timestamptz.to_i
    assert_equal 2_280_004_245, @timestamptz_berlin.to_i
  end

  def test_to_r
    assert_instance_of Rational, @timestamptz.to_r
    assert_equal 2_272_147_200.to_r, Teasy::TimeWithZone.new(2042).to_r
    time_with_zone = Teasy::TimeWithZone.new(
      2042, 1, 1, 1, 0, 0, 0, 'Europe/Berlin')
    assert_equal 2_272_147_200.to_r, time_with_zone.to_r
  end

  def test_to_s
    assert_equal '2042-04-02 00:30:45 UTC', @timestamptz.to_s
    assert_equal '2042-04-02 00:30:45 +0200', @timestamptz_berlin.to_s
    timestamptz = Teasy.stub(:default_zone, 'Europe/Berlin') do
      Teasy::TimeWithZone.new(2042)
    end
    assert_equal '2042-01-01 00:00:00 +0100', timestamptz.to_s
  end

  def test_tuesday?
    tuesday = Teasy::TimeWithZone.new(2042, 4, 1)
    tuesday_berlin = Teasy::TimeWithZone.new(
      2042, 4, 1, 0, 0, 0, 0, 'Europe/Berlin')
    assert_equal true, tuesday.tuesday?
    assert_equal true, tuesday_berlin.tuesday?
    assert_equal false, @timestamptz.tuesday?
    assert_equal false, @timestamptz_berlin.tuesday?
  end

  def test_usec
    assert_equal 1, @timestamptz.usec
    assert_equal 1, @timestamptz_berlin.usec
  end

  def test_utc
    assert_instance_of Teasy::TimeWithZone, @timestamptz.utc
    assert_instance_of Teasy::TimeWithZone, @timestamptz_berlin.utc
    assert_equal @timestamptz, @timestamptz.utc
    assert_equal @timestamptz_berlin, @timestamptz_berlin.utc
    assert @timestamptz_berlin.utc.utc?
    refute_equal @timestamptz.object_id, @timestamptz.utc.object_id
  end

  def test_utc!
    timestamptz = @timestamptz.dup.utc!
    timestamptz_berlin = @timestamptz_berlin.dup.utc!
    assert_instance_of Teasy::TimeWithZone, timestamptz
    assert_instance_of Teasy::TimeWithZone, timestamptz_berlin
    assert_equal @timestamptz, timestamptz
    assert_equal @timestamptz_berlin, timestamptz_berlin
    assert timestamptz_berlin.utc?
    assert_equal timestamptz.object_id, timestamptz.utc!.object_id
  end

  def test_utc?
    assert @timestamptz.utc?
    refute @timestamptz_berlin.utc?
  end

  def test_utc_offset
    assert_equal 0, @timestamptz.utc_offset
    assert_equal 7200, @timestamptz_berlin.utc_offset
  end

  def test_wday
    assert_equal 3, @timestamptz.wday
    assert_equal 3, @timestamptz_berlin.wday
  end

  def test_wednesday?
    assert_equal true, @timestamptz.wednesday?
    assert_equal true, @timestamptz_berlin.wednesday?
    assert_equal false, (@timestamptz + 86_400).wednesday?
    assert_equal false, (@timestamptz_berlin + 86_400).wednesday?
  end

  def test_yday
    assert_equal 92, @timestamptz.yday
    assert_equal 92, @timestamptz_berlin.yday
  end

  def test_year
    assert_equal 2042, @timestamptz.year
    assert_equal 2042, @timestamptz_berlin.year
  end

  def test_zone
    assert_equal 'UTC', @timestamptz.zone
    assert_equal 'Europe/Berlin', @timestamptz_berlin.zone
  end

  def test_httpdate
    assert_equal 'Wed, 02 Apr 2042 00:30:45 GMT', @timestamptz.httpdate
    assert_equal 'Tue, 01 Apr 2042 22:30:45 GMT', @timestamptz_berlin.httpdate
  end

  def test_rfc2822
    assert_equal 'Wed, 02 Apr 2042 00:30:45 -0000', @timestamptz.rfc2822
    assert_equal 'Wed, 02 Apr 2042 00:30:45 +0200', @timestamptz_berlin.rfc2822
  end

  def test_rfc822
    assert_equal 'Wed, 02 Apr 2042 00:30:45 -0000', @timestamptz.rfc822
    assert_equal 'Wed, 02 Apr 2042 00:30:45 +0200', @timestamptz_berlin.rfc822
  end

  def test_xmlschema
    assert_equal '2042-04-02T00:30:45Z', @timestamptz.xmlschema
    assert_equal '2042-04-02T00:30:45+02:00', @timestamptz_berlin.xmlschema
  end

  def test_iso8601
    assert_equal '2042-04-02T00:30:45Z', @timestamptz.iso8601
    assert_equal '2042-04-02T00:30:45+02:00', @timestamptz_berlin.iso8601
  end
end
