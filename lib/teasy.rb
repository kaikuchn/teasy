require 'teasy/version'
require 'teasy/time_with_zone'

module Teasy
  def self.default_zone
    Thread.current[:teasy_default_zone] ||= 'UTC'
  end
end
