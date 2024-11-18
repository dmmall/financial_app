# frozen_string_literal: true

module Parsers
  class AmountParser
    class << self
      def parse(value)
        return nil if value.blank?

        case value
        when Numeric then value.to_d
        when String then parse_string(value)
        end
      rescue ArgumentError, TypeError
        nil
      end

      private

      def parse_string(string)
        string.delete(',').to_d
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
