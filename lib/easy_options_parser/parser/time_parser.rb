# frozen_string_literal: true

class EasyOptionsParser
  class Parser
    # internally used to parse
    # command line param to Time
    # object
    class TimeParser
      def self.accepts_option?(option_type)
        option_type.to_s == 'time'
      end

      def parse(value, _option_type)
        Time.parse(value)
      end
    end
  end
end
