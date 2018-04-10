require 'ostruct'
require 'bigdecimal'
require 'optparse'
require 'active_support/all'
require 'io/console'

class DynamicOptionsParser
  attr_reader :options, :cli_description

  def infer_class(option_type)
    return option_type if option_type.is_a?(Class)
    return Array if option_type.to_s.match(/^array:?/)
    return Array if option_type.to_s == 'dir_glob'
    return String if option_type.to_s == 'dir'

    case option_type.to_s
    when 'read_file'
      ReadFile
    when 'boolean'
      BooleanParser
    else
      Class.const_get(option_type.to_s.classify)
    end
  end

  def cli_description=(cli_description)
    @cli_description = cli_description
  end

  def assign_to(assign_to)
    @options = assign_to
  end

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

      opts.accept(ReadFile) do |value|
        ReadFile.new(value)
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
      elsif(option_type.to_s == 'dir_glob')
        value = Dir.glob(value[0])
      elsif(option_type.to_s == 'dir')
        raise "The path: #{value} does not exist" unless File.exist?(value)
        raise "The path: #{value} is not a directory" unless File.directory?(value)
      end

      value = yield(value) if block_given?

      @options.send("#{method_name}=", value)
    end

    self
  end

  def parse
    @help_arg_passed = false
    @op.banner = "#{cli_description ? "#{cli_description}\n" : ""}Usage: ruby #{@main_path} [options]"

    @options ||= OpenStruct.new

    @setup.each do |key, details|
      add_option(*([key] + details))
    end

    set_defaults
    @op.parse!

    validate_options

    options
  end

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

  private

  def process_array_with_sub_type(option_type, value)
    sub_type = option_type.to_s.match(/^array:(\w+)/)[1]
    value.collect{ |v| infer_class(sub_type).new(v) }
  end

  def show_help_text_and_exit
    puts @op
    exit
  end

  def validate_options
    return if @help_arg_passed

    missing_options = @required_options.keys.select do |method_name|
      required = @required_options[method_name]
      required && !@options.send(method_name)
    end

    raise "#{missing_options.to_sentence.gsub(/, and/, ' and')} must be specified, use --help for options" unless missing_options.empty?
  end

  def set_defaults
    @defaults.each do |method_name, default|
      @options.send("#{method_name}=", default)
    end
  end
end
