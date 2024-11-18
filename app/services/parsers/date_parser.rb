# frozen_string_literal: true

module Parsers
  class DateParser
    class << self
      def parse(value)
        return nil if value.blank?

        case value
        when Time, DateTime, ActiveSupport::TimeWithZone then value
        when Date then value.in_time_zone
        when String then parse_string(value)
        end
      rescue ArgumentError, TypeError
        nil
      end

      private

      def parse_string(string)
        Time.zone.parse(string) ||
          DateTime.parse(string).in_time_zone ||
          Date.parse(string).in_time_zone
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
