require 'teasy/version'
require 'teasy/time_with_zone'
require 'teasy/floating_time'

module Teasy
  def self.default_zone
    Thread.current[:teasy_default_zone] ||= 'UTC'
  end

  def self.default_zone=(zone)
    Thread.current[:teasy_default_zone] = zone
  end

  def self.with_zone(zone)
    old_zone = Thread.current[:teasy_default_zone]
    Thread.current[:teasy_default_zone] = zone
    block_result = yield
    Thread.current[:teasy_default_zone] = old_zone
    block_result
  end
end
