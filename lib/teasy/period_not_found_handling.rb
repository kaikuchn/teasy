# frozen_string_literal: true

module Teasy
  module PeriodNotFoundHandling
    UnknownPeriodNotFoundHandler = Class.new(StandardError)

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def period_not_found_handler
        Thread.current[:teasy_period_not_found_handler] ||= HANDLER[:raise]
      end

      def period_not_found_handler=(name_or_callable)
        if name_or_callable.respond_to?(:call)
          Thread.current[:teasy_period_not_found_handler] = name_or_callable
        else
          Thread.current[:teasy_period_not_found_handler] = HANDLER.fetch(
            name_or_callable.to_sym
          ) do |key|
            raise UnknownPeriodNotFoundHandler,
                  "Don't know a PeriodNotFound handler `#{key}`."
          end
        end
      end

      def with_period_not_found_handler(handler)
        old_handler = period_not_found_handler
        self.period_not_found_handler = handler
        yield
      ensure
        self.period_not_found_handler = old_handler
      end

      HANDLER = {
        raise: ->(_time, _zone) { raise },
        # the biggest change in offsets known to me is when Samoa went from -11
        # to +13 (a full day!) so hopefully we're sure to leave the unknown
        # period by adding/subtracting 3 days
        next_period: lambda do |time, zone|
          period = zone.period_for_local(time + 3 * 86_400)
          [period, period.start_transition.time + period.utc_total_offset]
        end,
        previous_period: lambda do |time, zone|
          period = zone.period_for_local(time - 3 * 86_400)
          [period, period.end_transition.time + period.utc_total_offset]
        end
      }.freeze
    end
  end
end
