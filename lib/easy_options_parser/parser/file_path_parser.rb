# frozen_string_literal: true

class EasyOptionsParser
  class Parser
    # internally used to parse
    # command line param to
    # file path validating
    # that path exists
    class FilePathParser
      def self.accepts_option?(option_type)
        option_type.to_s == 'read_file'
      end

      def parse(value, _option_type)
        raise "Path #{value} does not exist" unless File.exist?(value)

        value
      end
    end
  end
end
