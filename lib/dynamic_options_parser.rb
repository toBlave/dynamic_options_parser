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

    if(option_type.to_s == 'read_file')
      ReadFile
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

      opts.accept(Date) do |value|
        Date.parse(value)
      end

      opts.accept(ReadFile) do |value|
        ReadFile.new(value)
      end

      opts.accept(Symbol) do |value|
        value.to_sym
      end

      @first_letters = {}

      opts.on("-h", "--help", "Prints this help") do
        show_help_text_and_exit
      end
    end
  end

  def add_option(option_name, option_type, description = nil, default = nil)
  method_name = option_name.to_s.gsub(/\W/, '_')

  @defaults[method_name] = default

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

  @op.on("-#{char}#{variable_name}", "--#{option_name.to_s.gsub(/_/, '-')} #{variable_name}", option_type_class, description) do |value|
    if(option_type.to_s.match(/^array:/))
      value = process_array_with_sub_type(option_type, value)
    elsif(option_type.to_s == 'dir_glob')
      value = Dir.glob(value[0])
    end

    value = yield(value) if block_given?

    @options.send("#{method_name}=", value)
  end

  self
end

def parse
  @op.banner = "#{cli_description ? "#{cli_description}\n" : ""}Usage: ruby #{@main_path} [options]"

  @options ||= OpenStruct.new

  @setup.each do |key, details|
    add_option(*([key] + details))
  end

  set_defaults

  @op.parse!
  options
end

class ReadFile
  attr_reader :path

  def initialize(path)
    @path = path

    raise ArgumentError.new("#{path} does not exist") unless File.exists?(path)
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

def set_defaults
  @defaults.each do |method_name, default|
    @options.send("#{method_name}=", default)
  end
end
end
