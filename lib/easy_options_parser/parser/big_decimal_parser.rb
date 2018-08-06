# frozen_string_literal: true

class EasyOptionsParser
  class Parser
    # internally used to parse
    # command line param to big decimal
    class BigDecimalParser
      def self.accepts_option?(option_type)
        option_type.to_s == 'big_decimal'
      end

      def parse(value, _option_type)
        BigDecimal(value)
      end
    end
  end
end
