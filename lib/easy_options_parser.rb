# frozen_string_literal: true

require 'ostruct'
require 'bigdecimal'
require 'optparse'
require 'active_support/all'
require 'io/console'
require File.expand_path('easy_options_parser/parser_factory', __dir__)
require File.expand_path('easy_options_parser/opt_parse_translator', __dir__)
require File.expand_path('easy_options_parser/options_validator', __dir__)

# Sets up native ruby opt parser
class EasyOptionsParser
  attr_reader :options, :cli_description

  # Creates an EasyOptionsParser with optional setup options
  #
  # @param [Hash] setup may contain one or all of the following
  #   * :_cli_description - Is set it this option will override
  #                         the default description in the help text (--help)
  #   * :_assign_to - If set, the options passed to the
  #                   command line will be set on the passed on object
  def initialize(setup = {})
    @main_path = find_main_path
    @defaults = {}
    @required_options = {}
    @methods = []
    @cli_description = setup.delete(:_cli_description)
    assign_to(setup.delete(:_assign_to))
    @opt_parse_setup = nil
    @setup = setup
    @options_validator = OptionsValidator.new(self)
    setup_native_opt_parser
  end

  # Overrides the description given in the help text.
  # Calling this is the same as passing :_cli_description
  # to the constructor
  # @param [String] cli_description - The description to show in the help text
  attr_writer :cli_description

  # Overrides the default parsing behaviour by
  # assigning the options value to the object passed into this method
  # @param [Object] assign_to - the object to assign the commnd line option to.
  #                             It is assumed that the appropriate writer
  #                             methods available on the object
  def assign_to(assign_to)
    @options = assign_to
  end

  # Adds an option to the command line parser
  # @param [Symbol] option_name - The name of the option.
  #                               This will translate to an option flag.
  #                               eg: :option_1 will define
  #                               a cli option --option-1
  # @param [Symbol] option_type - Determines the option type.
  #                               Unless specified below this param
  #                               will be evaluated to a class
  #                               :string to String,
  #                               :time to Time.
  # @param [String] description - The description of this option.
  #                               This will appear in the help text when
  #                               a user passes --help
  def add_option(option_name, _option_type,
                 description = nil, additional_options = {})

    method_name = option_name.to_s.gsub(/\W/, '_')
    assigned_longhand = determine_longhand_flag(option_name)

    setup_option(method_name: method_name,
                 assigned_longhand: assigned_longhand,
                 additional_options: additional_options,
                 description: description)

    self
  end

  # Parses the command line arguments to the options specified in the setup
  # @return [Object] Either the object passed into assign_to or a new object
  # with the options defined avaiable as methods
  def parse
    @help_arg_passed = false
    @op.banner = "#{cli_description ? "#{cli_description}\n" : ''}"\
      "Usage: ruby #{@main_path} [options]"

    @options ||= Struct.new(*@methods).new

    set_defaults
    @op.parse!

    validate_options

    options
  end

  private

  def find_main_path
    caller_locations.detect do |l|
      l.base_label.match(/<main>/)
    end.try(:path) || 'main_file.rb'
  end

  def setup_option(params)
    register_option_and_default(params)

    description = generate_option_description(params)

    params[:description] = description

    define_option_on_native_parser(params)
  end

  def generate_option_description(params)
    base_description = params.fetch(:base_description)
    default = params.fetch(:default)
    required = params.fetch(:required)

    if default
      "#{base_description} (default: #{default})"
    elsif required
      "#{base_description} (required)"
    end
  end

  def register_option_and_default(params)
    method_name = params.fetch(:method_name)
    assigned_longhand = params.fetch(:assigned_longhand)
    additional_options = params.fetch(:additional_options)

    @methods << method_name.to_sym
    @defaults[method_name] = additional_options[:default]
    @required_options[method_name] = {
      assigned_longhand: "--#{assigned_longhand}",
      required: additional_options[:required]
    }
  end

  def setup_native_opt_parser
    @opt_parser_translator = OptParseTransalator.new(self)
    @opt_parser_translator.translate_easy_options
  end

  def determine_longhand_flag(option_name)
    option_name.to_s.tr('_', '-')
  end


  def define_option_on_native_parser(options)
    option_type = options[:option_type]
    parser = ParserFactory.instance.parser(option_type)

    if parser
      assign_native_option_to_parser(parser, options)
    else
      assign_native_option_to_class(options)
    end
  end

  def determine_shorthand_char(option_name)
    char = option_name.to_s.gsub(/[^A-Za-z]/, '').chars.detect do |c|
      !@first_letters[c.to_s]
    end

    char ||= ('a'..'z').to_a.detect do |c|
      !@first_letters[c]
    end

    @first_letters[char.to_s] = char

    char
  end

  def infer_class(option_type)
    return option_type if option_type.is_a?(Class)

    Class.const_get(option_type.to_s.classify)
  end

  def show_help_text_and_exit(exit_code = 0)
    puts @op
    exit exit_code
  end

  def validate_options
    @option_validator.validate
  end

  def set_defaults
    @defaults.each do |method_name, default|
      @options.send("#{method_name}=", default)
    end
  end

  def find_missing_options
    @required_options.keys.select do |method_name|
      required = @required_options[method_name][:required]
      required && !@options.send(method_name)
    end
  end
end
