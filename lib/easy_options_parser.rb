require 'ostruct'
require 'bigdecimal'
require 'optparse'
require 'active_support/all'
require 'io/console'

class EasyOptionsParser
  attr_reader :options, :cli_description

  # Creates an EasyOptionsParser with optional setup options
  #
  # @param [Hash] setup may contain one or all of the following
  #   * :_cli_description - Is set it this option will override the default description in the help text (--help)
  #   * :_assign_to - If set, the options passed to the command line will be set on the passed on object
  def initialize(setup = {})
    @main_path = caller_locations.detect { |l| l.base_label.match(/<main>/) }.try(:path) || 'main_file.rb'
    @defaults = {}
    @required_options = {}
    @methods = []
    cli_description = setup.delete(:_cli_description)
    assign_to(setup.delete(:_assign_to))

    @opt_parse_setup = nil
    @setup = setup

    @op = OptionParser.new do |opts|
      @opt_parse_setup = opts

      opts.accept(BigDecimal) do |value|
        BigDecimal(value)
      end

      opts.accept(DateTime) do |value|
        DateTime.parse(value)
      end

      opts.accept(Time) do |value|
        Time.parse(value)
      end

      opts.accept(Date) do |value|
        Date.parse(value)
      end

      opts.accept(BooleanParser) do |value|
        BooleanParser.new(value).parsed_value
      end

      opts.accept(Symbol, &:to_sym)

      @first_letters = {}

      opts.on('-h', '--help', 'Prints this help') do
        @help_arg_passed = true
        show_help_text_and_exit
      end
    end
  end

  # Overrides the description given in the help text. Calling this is the same as passing :_cli_description
  # to the constructor
  # @param [String] cli_description - The description to show in the help text
  attr_writer :cli_description

  # Overrides the default parsing behaviour by assigning the options value to the object passed into this method
  # @param [Object] assign_to - the object to assign the commnd line option to. It is assumed that the appropriate writer methods
  #                             available on the object
  def assign_to(assign_to)
    @options = assign_to
  end

  # Adds an option to the command line parser
  # @param [Symbol] option_name - The name of the option. This will translate to an option flag. eg: :option_1 will define a cli option --option-1
  # @param [Symbol] option_type - Determines the option type. Unless specified below this param will be evaluated to a class :string to String, :date_time to DateTime.
  # @param [String] description - The description of this option. This will appear in the help text when a user passes --help
  def add_option(option_name, option_type, description = nil, additional_options = {})
    method_name = option_name.to_s.gsub(/\W/, '_')
    assigned_longhand = determine_longhand_flag(option_name)

    @methods << method_name.to_sym
    @defaults[method_name] = additional_options[:default]
    @required_options[method_name] = { assigned_longhand: "--#{assigned_longhand}",
                                       required: additional_options[:required] }

    if additional_options[:default]
      description = "#{description} (default: #{additional_options[:default]})"
    elsif additional_options[:required]
      description = "#{description} (required)"
    end

    define_option_on_native_parser(
      option_name: option_name,
      option_type: option_type,
      description: description,
      method_name: method_name,
      assigned_longhand: assigned_longhand
    )

    self
  end

  # Parses the command line arguments to the options specified in the setup
  # @return [Object] Either the object passed into assign_to or a new object with the options defined avaiable as methods
  def parse
    @help_arg_passed = false
    @op.banner = "#{cli_description ? "#{cli_description}\n" : ''}Usage: ruby #{@main_path} [options]"

    @options ||= Struct.new(*@methods).new

    set_defaults
    @op.parse!

    validate_options

    options
  end

  private

  class ReadFile
    attr_reader :path

    def initialize(path)
      @path = path

      raise ArgumentError, "#{path} does not exist" unless File.exist?(path)
    end
  end

  class BooleanParser
    def initialize(value)
      @value = value
    end

    def parsed_value
      case @value
      when '1', 'true', 'TRUE', 't', 'T'
        true
      when '0', 'false', 'FALSE', 'f', 'F'
        false
      else
        raise "Invalid boolean value #{@value.inspect}"
      end
    end
  end

  def determine_longhand_flag(option_name)
    option_name.to_s.tr('_', '-')
  end

  def define_option_on_native_parser(options)
    option_type = options[:option_type]
    assigned_shorthand = determine_shorthand_char(options[:option_name])
    variable_name = option_name.to_s.gsub(/\W/, '_').upcase

    @op.on("-#{assigned_shorthand}#{variable_name}",
           "--#{options[:assigned_longhand]} #{variable_name}",
           infer_class(option_type),
           options[:description]) do |value|
      value = process_option_value(option_type, value)
      value = yield(value) if block_given?

      @options.send("#{optiosns[:method_name]}=", value)
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

  def process_individual_item_type(option_type, value)
    return Dir.glob(value[0]) if option_type.to_s == 'dir_glob'

    validate_file_path_exists(value) if option_type == 'read_file'
    validate_directory_path(value) if option_type == 'dir'

    value
  end

  def validate_file_path_exists(value)
    raise "The path: #{value} does not exist" unless File.exist?(value)
  end

  def validate_directory_path(value)
    validate_file_path_exists(value)

    raise "The path: #{value} is not a directory" unless File.directory?(value)
  end

  def infer_class(option_type)
    return option_type if option_type.is_a?(Class)
    return Array if option_type.to_s =~ /^array:?/
    return Array if option_type.to_s == 'dir_glob'
    return String if %w[read_file dir].include?(option_type.to_s)

    case option_type.to_s
    when 'boolean'
      BooleanParser
    else
      Class.const_get(option_type.to_s.classify)
    end
  end

  def process_array_with_sub_type(option_type, value)
    sub_type = option_type.to_s.match(/^array:(\w+)/)[1]
    klass = infer_class(sub_type)

    value.collect do |v|
      if klass == String
        process_individual_item_type(sub_type, v)
      else
        klass.new(v)
      end
    end
  end

  def show_help_text_and_exit(exit_code = 0)
    puts @op
    exit exit_code
  end

  def validate_options
    return if @help_arg_passed

    missing_options = find_missing_options

    return if missing_options.empty?

    longhand_flags = missing_options.collect do |method_name|
      @required_options[method_name][:assigned_longhand]
    end

    puts "#{longhand_flags.to_sentence.gsub(/, and/, ' and')} must be"\
      ' specified'
    show_help_text_and_exit 1
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

  def process_option_value(option_type, value)
    if option_type.to_s =~ /^array:/
      process_array_with_sub_type(option_type, value)
    else
      process_individual_item_type(option_type, value)
    end
  end
end
