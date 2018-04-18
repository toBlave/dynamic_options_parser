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
  #   * :_assign_to - Not compltely tested. If set, the options passed to the command line will be set on the passed on object
  def initialize(setup = {})
    @main_path = caller_locations.detect{|l| l.base_label.match(/<main>/)}.try(:path) || 'main_file.rb'
    @defaults = {}
    @required_options = {}
    cli_description = setup.delete(:_cli_description)
    assign_to(setup.delete(:_assign_to))

    @opt_parse_setup = nil
    @setup = setup

    @op = OptionParser.new do |opts|
      @opt_parse_setup = opts

      opts.accept(BigDecimal) do |value|
        BigDecimal.new(value)
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

      opts.accept(Symbol) do |value|
        value.to_sym
      end

      @first_letters = {}

      opts.on("-h", "--help", "Prints this help") do
        @help_arg_passed = true
        show_help_text_and_exit
      end
    end
  end

  # Overrides the description given in the help text. Calling this is the same as passing :_cli_description
  # to the constructor
  # @param [String] cli_description - The description to show in the help text
  def cli_description=(cli_description)
    @cli_description = cli_description
  end

  # Not fully tested. By default this the parse method will create an object whose methods will return the options passed in on the command line
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

    @defaults[method_name] = additional_options[:default]
    @required_options[method_name] = additional_options[:required]

    char = option_name.to_s.gsub(/[^A-Za-z]/, '').chars.detect do |c|
      !@first_letters[c.to_s]
    end

    unless(char)
      char = ('a'..'z').to_a.detect do |c|
        !@first_letters[c]
      end
    end

    @first_letters[char.to_s] = char

    variable_name = option_name.to_s.gsub(/\W/, "_").upcase

    option_type_class = infer_class(option_type)

    if(additional_options[:default])
      description = "#{description.to_s} (default: #{additional_options[:default]})"
    elsif(additional_options[:required])
      description = "#{description.to_s} (required)"
    end

    @op.on("-#{char}#{variable_name}", "--#{option_name.to_s.gsub(/_/, '-')} #{variable_name}", option_type_class, description) do |value|
      if(option_type.to_s.match(/^array:/))
        value = process_array_with_sub_type(option_type, value)
      else
        value = process_individual_item_type(option_type, value)
      end

      value = yield(value) if block_given?

      @options.send("#{method_name}=", value)
    end

    self
  end

  # Parses the command line arguments to the options specified in the setup
  # @return [Object] Either the object passed into assign_to or a new object with the options defined avaiable as methods
  def parse
    @help_arg_passed = false
    @op.banner = "#{cli_description ? "#{cli_description}\n" : ""}Usage: ruby #{@main_path} [options]"

    @options ||= OpenStruct.new

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

      raise ArgumentError.new("#{path} does not exist") unless File.exists?(path)
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

  def process_individual_item_type(option_type, value)
    if(option_type.to_s == 'dir_glob')
      return Dir.glob(value[0])
    elsif(option_type.to_s == 'dir')
      raise "The path: #{value} does not exist" unless File.exist?(value)
      raise "The path: #{value} is not a directory" unless File.directory?(value)
    elsif(option_type.to_s == 'read_file')
      raise "The path: #{value} does not exist" unless File.exist?(value)
    end

    return value
  end

  def infer_class(option_type)
    return option_type if option_type.is_a?(Class)
    return Array if option_type.to_s.match(/^array:?/)
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
      if(klass == String)
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

    missing_options = @required_options.keys.select do |method_name|
      required = @required_options[method_name]
      required && !@options.send(method_name)
    end

    unless missing_options.empty?
     puts "#{missing_options.to_sentence.gsub(/, and/, ' and')} must be specified"
     show_help_text_and_exit 1
    end
  end

  def set_defaults
    @defaults.each do |method_name, default|
      @options.send("#{method_name}=", default)
    end
  end
end
