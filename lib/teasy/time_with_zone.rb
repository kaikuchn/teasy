# frozen_string_literal: true

require 'tzinfo'
require 'forwardable'

module Teasy
  # rubocop:disable Metrics/ClassLength
  class TimeWithZone
    extend Forwardable
    include Comparable

    def_delegators :time, :year, :mon, :month, :day, :hour, :min, :minute, :sec,
                   :usec, :nsec, :subsec, :mday, :wday, :yday, :monday?,
                   :tuesday?, :wednesday?, :thursday?, :friday?, :saturday?,
                   :sunday?
    def_delegators :period, :dst?
    def_delegator :period, :utc_total_offset, :utc_offset
    def_delegators :to_time, :to_i, :to_r, :to_f, :to_datetime, :to_date,
                   :httpdate, :rfc2822, :rfc822, :xmlschema, :iso8601

    # rubocop:disable Metrics/ParameterLists
    def initialize(year, month = nil, day = nil,
                   hour = nil, minute = nil, second = nil, usec_with_frac = nil,
                   zone = Teasy.default_zone)
      @zone = TZInfo::Timezone.get(zone)
      @time = Time.utc(year, month, day, hour, minute, second, usec_with_frac)
      @period = determine_period(@time, @zone)
    end
    # rubocop:enable Metrics/ParameterLists

    def self.from_time(time, zone = Teasy.default_zone)
      new(time.year, time.mon, time.day, time.hour, time.min, time.sec,
          time.nsec / 1_000.0, zone)
    end

    def self.from_utc(utc_time, zone = Teasy.default_zone)
      from_time(utc_time, 'UTC').in_time_zone!(zone)
    end

    def self.parse(string, zone = Teasy.default_zone)
      from_utc(Time.parse(string).utc, zone)
    end

    def self.iso8601(string, zone = Teasy.default_zone)
      from_utc(Time.iso8601(string).utc, zone)
    end

    def self.strptime(string, format, zone = Teasy.default_zone)
      new(*DateTime._strptime(string, format).values, 'UTC').in_time_zone!(zone)
    end

    def in_time_zone!(zone = Teasy.default_zone)
      time = utc_time
      @zone = TZInfo::Timezone.get(zone)
      @time = @zone.utc_to_local(time)
      @period = @zone.period_for_utc(time)
      remove_instance_variable(:@local_time) unless @local_time.nil?
      self
    end

    def in_time_zone(zone = Teasy.default_zone)
      dup.in_time_zone!(zone)
    end

    def zone
      @zone.identifier
    end

    def utc?
      @zone.identifier == 'UTC'
    end

    def utc!
      @time = @zone.local_to_utc(@time, @period.dst?)
      @zone = TZInfo::Timezone.get('UTC')
      @period = @zone.period_for_local(@time)
      self
    end

    def utc
      dup.utc!
    end

    def round!(*args)
      @time = @time.round(*args)
      self
    end

    def round(*args)
      dup.round!(*args)
    end

    def inspect
      format = utc? ? '%Y-%m-%d %H:%M:%S %Z' : '%Y-%m-%d %H:%M:%S %z'
      strftime(format)
    end

    alias to_s inspect

    def strftime(format)
      format = replace_zone_info(format) if includes_zone_directive?(format)
      time.strftime(format)
    end

    def asctime
      strftime('%a %b %e %T %Y')
    end

    alias ctime asctime

    def +(other)
      TimeWithZone.from_utc(utc_time + other, @zone.identifier)
    end

    def -(other)
      if other.is_a? Numeric
        TimeWithZone.from_utc(utc_time - other, @zone.identifier)
      elsif other.respond_to? :to_time
        to_time - other.to_time
      else
        raise TypeError, "#{other.class} can't be coerced into TimeWithZone"
      end
    end

    def <=>(other)
      return nil unless other.respond_to? :to_time
      to_time <=> other.to_time
    end

    def eql?(other)
      hash == other.hash
    end

    def hash
      (utc.to_a << self.class).hash
    end

    def to_a
      time.to_a[0..7] + [dst?, period.abbreviation.to_s]
    end

    def to_time
      return @local_time unless @local_time.nil?
      params = %i[year mon day hour min].map! { |m| @time.send(m) }
      params << @time.sec + @time.subsec
      @local_time = utc? ? Time.utc(*params) : Time.new(*params, utc_offset)
    end

    private

    def determine_period(time, zone = Teasy.default_zone)
      zone.period_for_local(time) do |results|
        Teasy.ambiguous_time_handler.call(results, time)
      end
    rescue TZInfo::PeriodNotFound
      period, time = Teasy.period_not_found_handler.call(time, zone)
      @time = time
      period
    end

    def utc_time
      @utc_time ||= @zone.local_to_utc(@time)
    end

    attr_reader :time, :period

    # matches valid format directives for zones
    ZONE_ABBREV = /(?<!%)%Z/
    ZONE_NO_COLON_OFFSET = /(?<!%)%z/
    ZONE_COLON_OFFSET = /(?<!%)%:z/
    ZONE_COLONS_OFFSET = /(?<!%)%::z/

    def zone_directives_matcher
      @zone_directives_matcher ||= Regexp.union(
        ZONE_ABBREV, ZONE_NO_COLON_OFFSET, ZONE_COLON_OFFSET, ZONE_COLONS_OFFSET
      )
    end

    def includes_zone_directive?(format)
      zone_directives_matcher =~ format
    end

    def replace_zone_info(format)
      format_with_zone = format.gsub(ZONE_ABBREV, period.abbreviation.to_s)
      format_with_zone.gsub!(ZONE_NO_COLON_OFFSET, formatted_offset(utc_offset))
      format_with_zone.gsub!(
        ZONE_COLON_OFFSET, formatted_offset(utc_offset, :with_colon)
      )
      format_with_zone.gsub!(
        ZONE_COLONS_OFFSET,
        formatted_offset(utc_offset, :with_colon, :with_seconds)
      )
      format_with_zone
    end

    def formatted_offset(offset_in_seconds, colon = false, seconds = false)
      string_format = +'%s%02d:%02d'
      string_format.concat(':%02d') if seconds
      string_format.delete!(':') unless colon

      sign = offset_in_seconds.negative? ? '-' : '+'
      hours = offset_in_seconds.abs / 3600
      minutes = (offset_in_seconds.abs % 3600) / 60
      seconds = (offset_in_seconds.abs % 60)

      format(string_format, sign, hours, minutes, seconds)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
