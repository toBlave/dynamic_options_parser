# frozen_string_literal: true

class EasyOptionsParser
  # validates options
  # passed into command line
  class OptionsValidator
    def initialize(easy_options_parser)
      @easy_options_parser = easy_options_parser
    end

    def validate_options
      return if @easy_options_parser.help_arg_passed

      missing_options = find_missing_options

      return if missing_options.empty?

      longhand_flags = missing_options.collect do |method_name|
        @easy_options_parser.required_options[method_name][:assigned_longhand]
      end

      puts "#{longhand_flags.to_sentence.gsub(/, and/, ' and')} must be"\
        ' specified'
      show_help_text_and_exit 1
    end
  end
end
