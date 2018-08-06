# frozen_string_literal: true

class EasyOptionsParser
  class Parser
    # internally used to parse
    # command line param to directory
    # path validating first
    # that path exists and is
    # a directory
    class DirectoryPathParser < FilePathParser
      def self.accepts_option?(option_type)
        option_type.to_s == 'dir'
      end

      def parse(value, option_type)
        path = super

        unless File.directory?(path)
          raise "Path #{path} exists but is not a directory"
        end

        path
      end
    end
  end
end
