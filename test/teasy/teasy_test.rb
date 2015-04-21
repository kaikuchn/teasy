require 'test_helper'

class TeasyTest < Minitest::Test
  def teardown
    Teasy.default_zone = 'UTC'
  end

  def test_default_zone_is_utc
    assert_equal 'UTC', Teasy.default_zone
  end

  def test_default_zone_can_be_set
    assert_equal 'UTC', Teasy.default_zone
    Teasy.default_zone = 'Asia/Calcutta'
    assert_equal 'Asia/Calcutta', Teasy.default_zone
  end

  def test_default_zone_is_thread_safe
    assert_equal 'UTC', Teasy.default_zone
    threads = []
    threads << Thread.new do
      Teasy.default_zone = 'America/New_York'
      sleep 0.1
      assert_equal 'America/New_York', Teasy.default_zone
    end
    assert_equal 'UTC', Teasy.default_zone
    threads << Thread.new do
      assert_equal 'UTC', Teasy.default_zone
    end
    threads.each(&:join)
  end

  def test_with_zone
    assert_equal 'UTC', Teasy.default_zone
    Teasy.with_zone('Europe/Berlin') do
      assert_equal 'Europe/Berlin', Teasy.default_zone
    end
    assert_equal 'UTC', Teasy.default_zone
    assert_equal 1, Teasy.with_zone('Europe/Berlin') { 1 }
  end
end
