require 'test_helper'

class TimeWithZoneTest < Minitest::Unit::TestCase
  def setup
    @time = Time.utc(2042, 1, 2, 12, 30, 45, 1.112)
    @dtime = @time.to_datetime
  end
end
