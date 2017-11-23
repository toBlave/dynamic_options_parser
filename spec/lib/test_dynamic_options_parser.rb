require 'dynamic_options_parser'

class TestDynamicOptionsParser < DynamicOptionsParser
  def set_argv(argv)
    @op.default_argv = argv
  end

  def show_help_text_and_exit
    puts @op
  end
end
