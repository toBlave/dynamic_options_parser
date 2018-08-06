# frozen_string_literal: true

class EasyOptionsParser
  class Parser
    # internally used to parse
    # command line param to date
    class DateParser
      def self.accepts_option?(option_type)
        option_type.to_s == 'date'
      end

      def parse(value, _option_type)
        Date.parse(value)
      end
    end
  end
end
