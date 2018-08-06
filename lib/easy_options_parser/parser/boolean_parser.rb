# frozen_string_literal: true

class EasyOptionsParser
  class Parser
    # internally used to parse
    # command line param to boolean
    class BooleanParser
      def self.accepts_option?(option_type)
        option_type.to_s == 'boolean'
      end

      def parse(value, _option_type)
        case value
        when '1', 'true', 'TRUE', 't', 'T'
          true
        when '0', 'false', 'FALSE', 'f', 'F'
          false
        else
          raise "Invalid boolean value #{value.inspect}"
        end
      end
    end
  end
end
