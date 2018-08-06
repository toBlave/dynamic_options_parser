# frozen_string_literal: true

class EasyOptionsParser
  class Parser
    # internally used to parse
    # command line param to array
    class ArrayParser
      def self.accepts_option?(option_type)
        option_type.to_s.match(/^array(:)?/)
      end

      def parse(value, option_type)
        parser, inferred_class = determin_array_item_type(option_type)

        value.split(',').collect do |v|
          parse_individual_value(parser, inferred_class, sub_type, v)
        end
      end

      private

      def determine_array_item_type(option_type)
        inferred_class = nil
        parser = nil

        if /:/.match?(option_type)
          sub_type = option_type.split(/:/).last
          parser = ParserFactory.instance.parser(sub_type)

          unless parser
            inferred_class = Class.const_get(option_type.to_s.classify)
          end
        end

        [parser, inferred_class]
      end

      def parse_individual_value(parser, inferred_class, option_type, value)
        if parser
          parser.parse(value, option_type)
        elsif inferred_class
          inferred_class.new(value)
        else
          value
        end
      end
    end
  end
end
