# frozen_string_literal: true

require 'teasy/version'
require 'teasy/time_with_zone'
require 'teasy/floating_time'
require 'teasy/ambiguous_time_handling'
require 'teasy/period_not_found_handling'

module Teasy
  include AmbiguousTimeHandling
  include PeriodNotFoundHandling

  class << self
    def default_zone
      Thread.current[:teasy_default_zone] ||= 'UTC'
    end

    def default_zone=(zone)
      Thread.current[:teasy_default_zone] = zone
    end

    def with_zone(zone)
      old_zone = default_zone
      self.default_zone = zone
      yield zone
    ensure
      self.default_zone = old_zone
    end
  end
end
