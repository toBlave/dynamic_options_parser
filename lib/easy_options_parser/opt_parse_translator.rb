# frozen_string_literal: true

class EasyOptionsParser
  # Parses the option to base translator
  class OptParseTransalator
    def initialize(easy_options_parser)
      @easy_options_parser = easy_options_parser
    end

    def translate_easy_options
      @op = OptionParser.new do |opts|
        opts.opt_parse_setup = opts

        opts.accept(Symbol, &:to_sym)

        opts.on('-h', '--help', 'Prints this help') do
          @easy_options_parser.help_arg_passed = true
          @easy_options_parser.show_help_text_and_exit
        end
      end
    end

    def assign_native_option_to_parser(parser, options)
      option_name = options[:option_name]
      assigned_shorthand = determine_shorthand_char(option_name)
      variable_name = option_name.to_s.gsub(/\W/, '_').upcase

      @op.on("-#{assigned_shorthand}#{variable_name}",
             "--#{options[:assigned_longhand]} #{variable_name}",
             options[:description]) do |value|
               value = parser.parse(value, options[:option_type])
               value = yield(value) if block_given?
               @options.send("#{options[:method_name]}=", value)
             end
    end

    def assign_native_option_to_class(options)
      option_name = options[:option_name]
      assigned_shorthand = determine_shorthand_char(option_name)
      variable_name = option_name.to_s.gsub(/\W/, '_').upcase

      @op.on("-#{assigned_shorthand}#{variable_name}",
             "--#{options[:assigned_longhand]} #{variable_name}",
             infer_class(options[:option_type]),
             options[:description]) do |value|
               value = yield(value) if block_given?

               @options.send("#{options[:method_name]}=", value)
             end
    end
  end
end
