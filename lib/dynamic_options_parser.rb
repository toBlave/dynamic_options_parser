require 'ostruct'
require 'bigdecimal'
require 'byebug'
require 'optparse'
require 'active_support/all'

class DynamicOptionsParser
  attr_reader :options

  def infer_class(option_type)
    return option_type if option_type.is_a?(Class)

    if(option_type.to_s == 'read_file')
      ReadFile
    else
      Class.const_get(option_type.to_s.classify)
    end
  end

  def initialize(setup = {})
    @options = setup.delete(:assign_to) || OpenStruct.new
    description = setup.delete(:cli_description)

    @opt_parse_setup = nil

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

      opts.banner = "#{description ? "#{description}\n" : ""}Usage: ruby #{File.basename(__FILE__)} [options]"

      @first_letters = {}

      opts.on("-h", "--help", "Prints this help") do
        puts @op
        exit
      end
    end

    setup.each do |key, details|
      add_option(*([key] + details))
    end
  end

  def add_option(option_name, option_type, description = nil, default = nil)
    method_name = option_name.to_s.gsub(/\W/, '_')

    @options.send("#{method_name}=", default)   

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

    option_type = infer_class(option_type)

    @op.on("-#{char}#{variable_name}", "--#{option_name.to_s.gsub(/_/, '-')} #{variable_name}", option_type, description) do |value|
      @options.send("#{method_name}=", value)
    end

    self
  end

  def parse
    @op.parse!
    options   
  end

  class ReadFile
    attr_reader :path

    def initialize(path)
      @path = path

      raise "#{path} does not exist" unless File.exists?(path)
    end
  end
end
