require 'test_helper'

class FloatingTimeTest < Minitest::Test
  def setup
    @params = [2042, 4, 2, 0, 30, 45, 1.112]
    @timestamp = Teasy::FloatingTime.new(*@params)
  end

  def test_constructor_parameter
    assert_equal 2042, @timestamp.year
    assert_equal 4, @timestamp.month
    assert_equal 2, @timestamp.day
    assert_equal 0, @timestamp.hour
    assert_equal 30, @timestamp.min
    assert_equal 45, @timestamp.sec
    assert_equal 1_112, @timestamp.nsec
  end

  def test_from_time
    time = Time.new(*@params)
    timestamp = Teasy::FloatingTime.from_time(time)
    assert_instance_of Teasy::FloatingTime, timestamp
    assert_equal 0, timestamp.hour
  end

  def test_in_time_zone
    time = Teasy::FloatingTime.new(2014, 1, 1, 12)
    assert_equal Time.utc(2014, 1, 1, 12), time.in_time_zone
    assert_equal Time.utc(2014, 1, 1, 11), time.in_time_zone('Europe/Berlin')
    assert_equal Time.utc(2014, 1, 1, 6, 30), time.in_time_zone('Asia/Calcutta')
    assert_equal Time.utc(2014, 1, 1, 17), time.in_time_zone('America/New_York')
    assert_raises(TZInfo::AmbiguousTime) do
      Teasy::FloatingTime.new(2014, 10, 26, 2).in_time_zone('Europe/Berlin')
    end
    assert_raises(TZInfo::PeriodNotFound) do
      Teasy::FloatingTime.new(2014, 3, 30, 2, 30).in_time_zone('Europe/Berlin')
    end
  end

  def test_addition
    assert_equal 45, @timestamp.sec
    @timestamp += 5
    assert_equal 50, @timestamp.sec
    assert_instance_of Teasy::FloatingTime, @timestamp
  end

  def test_subtraction
    assert_equal 45, @timestamp.sec
    @timestamp -= 5
    assert_equal 40, @timestamp.sec
    assert_instance_of Teasy::FloatingTime, @timestamp
    assert_instance_of Float, @timestamp - @timestamp
    assert_equal 5.0, @timestamp - (@timestamp - 5)
  end

  def test_comparison
    timestamptz = Teasy::TimeWithZone.new(*@params, 'America/New_York')
    assert_operator @timestamp, :==, @timestamp
    assert_operator @timestamp, :==, Teasy::TimeWithZone.new(*@params)
    assert_operator @timestamp, :==, timestamptz
    refute_operator @timestamp, :==, timestamptz.utc
    assert_operator @timestamp, :>, (@timestamp - 1800)
    assert_operator @timestamp, :>, timestamptz.in_time_zone('America/Chicago')
    assert_operator @timestamp, :<, (@timestamp + 1800)
    assert_operator @timestamp, :<, timestamptz.in_time_zone('Asia/Calcutta')
  end

  def test_asctime
    assert_equal 'Wed Apr  2 00:30:45 2042', @timestamp.asctime
  end

  def test_ctime
    assert_equal 'Wed Apr  2 00:30:45 2042', @timestamp.ctime
  end

  def test_day
    assert_equal 2, @timestamp.day
    assert_equal 2, @timestamp.mday
  end

  def test_eql?
    assert @timestamp.eql?(@timestamp)
    refute @timestamp.eql?(@timestamp + 1)
    refute @timestamp.eql?(Teasy::TimeWithZone.new(*@params, 'Europe/Berlin'))
  end

  def test_friday?
    friday = Teasy::FloatingTime.new(2042, 04, 04)
    assert_equal true, friday.friday?
    assert_equal false, @timestamp.friday?
  end

  def test_hash
    assert_equal @timestamp.hash, @timestamp.dup.hash
    refute_equal @timestamp.hash, (@timestamp + 1).hash
    refute_equal @timestamp.hash, (Teasy::TimeWithZone.new(*@params)).hash
  end

  def test_hour
    assert_equal 0, @timestamp.hour
  end

  def test_inspect
    assert_equal '2042-04-02 00:30:45', @timestamp.inspect
  end

  def test_min
    assert_equal 30, @timestamp.min
  end

  def test_month
    assert_equal 4, @timestamp.month
    assert_equal 3, (@timestamp - 100_000).month
  end

  def test_mon
    assert_equal 4, @timestamp.mon
    assert_equal 3, (@timestamp - 100_000).mon
  end

  def test_monday?
    monday = Teasy::FloatingTime.new(2042, 03, 31)
    assert_equal true, monday.monday?
    assert_equal false, @timestamp.monday?
  end

  def test_nsec
    assert_equal 1_112, @timestamp.nsec
  end

  def test_round
    assert_instance_of Teasy::FloatingTime, @timestamp.round
    assert_equal 1_112, @timestamp.nsec
    assert_equal 0, @timestamp.round.nsec
    assert_equal 1_100, @timestamp.round(7).nsec
    assert_equal 1_112, @timestamp.round(9).nsec
  end

  def test_round!
    assert_equal 1_112, @timestamp.nsec
    assert_equal 1_112, @timestamp.round!(9).nsec
    assert_equal 1_110, @timestamp.round!(8).nsec
    assert_equal 1_100, @timestamp.round!(7).nsec
    assert_equal 1_000, @timestamp.round!(6).nsec
    assert_equal 0, @timestamp.round!.nsec
    assert_instance_of Teasy::FloatingTime, @timestamp.round!
    assert_equal @timestamp.object_id, @timestamp.round!.object_id
  end

  def test_saturday?
    saturday = Teasy::FloatingTime.new(2042, 4, 5)
    assert_equal true, saturday.saturday?
    assert_equal false, @timestamp.saturday?
  end

  def test_sec
    assert_equal 45, @timestamp.sec
    assert_equal 50, (@timestamp + 5).sec
  end

  def test_strftime
    assert_equal '00', @timestamp.strftime('%H')
    assert_equal '00 %z', @timestamp.strftime('%H %z')
    assert_equal '00 %:z', @timestamp.strftime('%H %:z')
    assert_equal '00 %::z', @timestamp.strftime('%H %::z')
    assert_equal '00 %Z', @timestamp.strftime('%H %Z')
    assert_equal '00 %Z', @timestamp.strftime('%H %%Z')
  end

  def test_subsec
    assert_equal 1.112.to_r / 1_000_000, @timestamp.subsec
  end

  def test_sunday?
    sunday = Teasy::FloatingTime.new(2042, 4, 6)
    assert_equal true, sunday.sunday?
    assert_equal false, @timestamp.sunday?
  end

  def test_thursday?
    thursday = Teasy::FloatingTime.new(2042, 4, 3)
    assert_equal true, thursday.thursday?
    assert_equal false, @timestamp.thursday?
  end

  def test_to_a
    assert_equal [45, 30, 0, 2, 4, 2042, 3, 92], @timestamp.to_a
  end

  def test_to_s
    assert_equal '2042-04-02 00:30:45', @timestamp.to_s
  end

  def test_tuesday?
    tuesday = Teasy::FloatingTime.new(2042, 4, 1)
    assert_equal true, tuesday.tuesday?
    assert_equal false, @timestamp.tuesday?
  end

  def test_usec
    assert_equal 1, @timestamp.usec
  end

  def test_utc
    utc_time = @timestamp.utc
    assert_instance_of Time, utc_time
    assert utc_time.utc?
    assert_equal '2042-04-02 00:30:45', utc_time.strftime('%F %T')
    assert_equal @timestamp, utc_time
  end

  def test_wday
    assert_equal 3, @timestamp.wday
  end

  def test_wednesday?
    assert_equal true, @timestamp.wednesday?
    assert_equal false, (@timestamp + 86_400).wednesday?
  end

  def test_yday
    assert_equal 92, @timestamp.yday
  end

  def test_year
    assert_equal 2042, @timestamp.year
  end
end
