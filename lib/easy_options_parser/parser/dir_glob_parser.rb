# frozen_string_literal: true

class EasyOptionsParser
  class Parser
    # internally used to parse
    # command line arg as
    # glob expression an return
    # matching file paths
    class DirGlobParser
      def self.accepts_option?(option_type)
        option_type.to_s == 'dir_glob'
      end

      def parse(value, _option_type)
        Dir.glob(value)
      end
    end
  end
end
