module Teasy
  class TimeWithZone < SimpleDelegator
    def self.from_time(time)
      new(Time.at(time))
    end

    def self.from_datetime(date_time)
      new(
        Time.new(
          date_time.year, date_time.month, date_time.day,
          date_time.hour, date_time.min, date_time.sec + date_time.sec_fraction,
          date_time.zone))
    end
  end
end
