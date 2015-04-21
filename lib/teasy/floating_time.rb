require 'tzinfo'
require 'forwardable'

module Teasy
  class FloatingTime
    extend Forwardable
    include Comparable

    def_delegators :time, :year, :mon, :month, :day, :hour, :min, :minute, :sec,
                   :usec, :nsec, :subsec, :mday, :wday, :yday, :monday?,
                   :tuesday?, :wednesday?, :thursday?, :friday?, :saturday?,
                   :sunday?

    # rubocop:disable Metrics/ParameterLists
    def initialize(year, month = nil, day = nil,
                   hour = nil, minute = nil, second = nil, usec_with_frac = nil)
      @time = Time.utc(year, month, day, hour, minute, second, usec_with_frac)
    end
    # rubocop:enable Metrics/ParameterLists

    def self.from_time(time)
      new(time.year, time.mon, time.day,
          time.hour, time.min, time.sec, time.nsec / 1_000.0)
    end

    def round!(*args)
      @time = time.round(*args)
      self
    end

    def round(*args)
      dup.round!(*args)
    end

    def inspect
      strftime('%Y-%m-%d %H:%M:%S')
    end

    alias_method :to_s, :inspect

    def strftime(format)
      format = prefix_zone_info(format) if includes_zone_directive?(format)
      time.strftime(format)
    end

    def asctime
      strftime('%a %b %e %T %Y')
    end

    alias_method :ctime, :asctime

    def <=>(other)
      return nil unless other.respond_to?(:to_time) &&
                        other.respond_to?(:utc_offset)
      to_time - other.utc_offset <=> other.to_time.utc
    end

    def eql?(other)
      hash == other.hash
    end

    def hash
      (to_a << self.class).hash
    end

    def +(other)
      FloatingTime.from_time(time + other)
    end

    def -(other)
      if other.is_a? Numeric
        FloatingTime.from_time(time - other)
      elsif other.respond_to? :to_time
        to_time - other.to_time
      else
        fail TypeError, "#{other.class} can't be coerced into FloatingTime"
      end
    end

    def to_a
      time.to_a[0..7]
    end

    def to_time
      time.dup
    end

    alias_method :utc, :to_time

    def utc_offset
      0
    end

    private

    attr_reader :time

    def self.zone_directives_matcher
      @zone_directives_matcher ||= Regexp.union(
        /(?<!%)%Z/, /(?<!%)%z/, /(?<!%)%:z/, /(?<!%)%::z/
      )
    end

    def includes_zone_directive?(format)
      FloatingTime.zone_directives_matcher =~ format
    end

    def prefix_zone_info(format)
      # prefixes zone directives with a % s.t. they are ignored in strftime
      format.gsub(FloatingTime.zone_directives_matcher) { |m| '%' + m }
    end
  end
  # rubocop:enable Metrics/ClassLength
end
