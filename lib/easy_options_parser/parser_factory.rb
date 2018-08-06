# frozen_string_literal: true

require File.expand_path('parser/big_decimal_parser', __dir__)
require File.expand_path('parser/boolean_parser', __dir__)
require File.expand_path('parser/date_parser', __dir__)
require File.expand_path('parser/file_path_parser', __dir__)
require File.expand_path('parser/directory_path_parser', __dir__)
require File.expand_path('parser/time_parser', __dir__)
require File.expand_path('parser/array_parser', __dir__)
require File.expand_path('parser/dir_glob_parser', __dir__)

# takes an option type
# and maps it to a parser
class ParserFactory
  include Singleton

  def initialize
    @parsers = []
  end

  def parser(option_type)
    parser_class(option_type)&.new
  end

  def register_parser(*parser_classes)
    @parsers += parser_classes
  end

  private

  def parser_class(option_type)
    @parsers.detect do |parser|
      parser.accepts_option?(option_type)
    end
  end
end

ParserFactory.instance.register_parser(
  EasyOptionsParser::Parser::BooleanParser,
  EasyOptionsParser::Parser::BigDecimalParser,
  EasyOptionsParser::Parser::DateParser,
  EasyOptionsParser::Parser::FilePathParser,
  EasyOptionsParser::Parser::DirectoryPathParser,
  EasyOptionsParser::Parser::TimeParser,
  EasyOptionsParser::Parser::ArrayParser,
  EasyOptionsParser::Parser::DirGlobParser
)
