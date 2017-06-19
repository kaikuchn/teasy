# frozen_string_literal: true

module Teasy
  module AmbiguousTimeHandling
    UnknownAmbiguousTimeHandler = Class.new(StandardError)
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def ambiguous_time_handler
        Thread.current[:teasy_ambiguous_time_handler] ||= HANDLER[:raise]
      end

      def ambiguous_time_handler=(name_or_callable)
        if name_or_callable.respond_to?(:call)
          Thread.current[:teasy_ambiguous_time_handler] = name_or_callable
        else
          Thread.current[:teasy_ambiguous_time_handler] = HANDLER.fetch(
            name_or_callable.to_sym
          ) do |key|
            raise UnknownAmbiguousTimeHandler,
                  "Don't know an ambiguous time handler `#{key}`."
          end
        end
      end

      def with_ambiguous_time_handler(handler)
        old_handler = ambiguous_time_handler
        self.ambiguous_time_handler = handler
        yield
      ensure
        self.ambiguous_time_handler = old_handler
      end

      HANDLER = {
        # By returning nil TZInfo will raise TZInfo::AmbigousTime. It'd be
        # better to raise our own error, but that would break the API that's out
        # there. So that will have to wait for a 1.x release.
        raise:                 ->(_time, _periods) {},
        daylight_savings_time: ->(_time, periods)  { periods.select(&:dst?) },
        standard_time:         ->(_time, periods)  { periods.reject(&:dst?) }
      }.freeze
    end
  end
end
