require 'tzinfo'

module Teasy
  def self.default_zone
    Thread.current[:teasy_default_zone] ||= 'UTC'
  end

  require 'forwardable'
  class TimeWithZone
    extend Forwardable
    include Comparable

    def_delegators :time, :year, :mon, :month, :day, :hour, :min, :minute, :sec,
                   :usec, :nsec, :subsec, :mday, :wday, :yday, :monday?,
                   :tuesday?, :wednesday?, :thursday?, :friday?, :saturday?,
                   :sunday?
    def_delegators :period, :dst?
    alias_method :isdst, :dst?
    def_delegator :period, :utc_total_offset, :utc_offset
    def_delegators :to_time, :hash, :to_i, :to_r, :to_f

    def initialize(year, month = nil, day = nil,
                   hour = nil, minute = nil, second = nil, usec_with_frac = nil,
                   zone = Teasy.default_zone)
      @zone = TZInfo::Timezone.get(zone)
      @time = Time.utc(year, month, day, hour, minute, second, usec_with_frac)
      @period = @zone.period_for_local(@time)
    end

    def self.from_time(time, zone = Teasy.default_zone)
      new(time.year, time.mon, time.day, time.hour, time.min, time.sec,
          time.nsec / 1_000.0, zone)
    end

    def zone
      @zone.identifier
    end

    def utc?
      @zone.identifier == 'UTC'
    end

    def utc
      @time = @zone.local_to_utc(@time)
      @zone = TZInfo::Timezone.get('UTC')
      @period = @zone.period_for_local(@time)
      self
    end

    def getutc
      dup.utc
    end

    def round(*args)
      TimeWithZone.from_time(time.round(*args), @zone.identifier)
    end

    def inspect
      format = utc? ? '%Y-%m-%d %H:%M:%S %Z' : '%Y-%m-%d %H:%M:%S %z'
      strftime(format)
    end

    alias_method :to_s, :inspect

    def strftime(format)
      format = replace_zone_info(format) if includes_zone_directive?(format)
      time.strftime(format)
    end

    def asctime
      strftime('%a %b %e %T %Y')
    end

    alias_method :ctime, :asctime

    def +(other)
      TimeWithZone.from_time(time + other, @zone.identifier)
    end

    def -(other)
      TimeWithZone.from_time(time - other, @zone.identifier)
    end

    def <=>(other)
      return nil unless other.respond_to? :to_time
      to_time <=> other.to_time
    end

    def ==(other)
      return false unless other.respond_to? :to_time
      to_time == other.to_time
    end

    alias_method :eql?, :==

    def to_a
      time.to_a[0..7] + [dst?, period.abbreviation.to_s]
    end

    def to_time
      @utc_time ||= @zone.local_to_utc(@time)
    end

    private

    attr_reader :time, :period

    # matches valid format directives for zones
    ZONE_ABBREV = /(?<!%)%Z/
    ZONE_NO_COLON_OFFSET = /(?<!%)%z/
    ZONE_COLON_OFFSET = /(?<!%)%:z/
    ZONE_COLONS_OFFSET = /(?<!%)%::z/

    def self.zone_directives_matcher
      @zone_directives_matcher ||= Regexp.union(ZONE_ABBREV,
                                                ZONE_NO_COLON_OFFSET,
                                                ZONE_COLON_OFFSET,
                                                ZONE_COLONS_OFFSET)
    end

    def includes_zone_directive?(format)
      TimeWithZone.zone_directives_matcher =~ format
    end

    def replace_zone_info(format)
      format_with_zone = format.gsub(ZONE_ABBREV, period.abbreviation.to_s)
      format_with_zone.gsub!(ZONE_NO_COLON_OFFSET, formatted_offset(utc_offset))
      format_with_zone.gsub!(
        ZONE_COLON_OFFSET, formatted_offset(utc_offset, :with_colon))
      format_with_zone.gsub!(
        ZONE_COLONS_OFFSET,
        formatted_offset(utc_offset, :with_colon, :with_seconds))
      format_with_zone
    end

    def formatted_offset(offset_in_seconds, colon = false, seconds = false)
      string_format = '%s%02d:%02d'
      string_format.concat(':%02d') if seconds
      string_format.delete!(':') unless colon

      sign = offset_in_seconds < 0 ? '-' : '+'
      hours = offset_in_seconds.abs / 3600
      minutes = (offset_in_seconds.abs % 3600) / 60
      seconds = (offset_in_seconds.abs % 60)

      format(string_format, sign, hours, minutes, seconds)
    end
  end
end
