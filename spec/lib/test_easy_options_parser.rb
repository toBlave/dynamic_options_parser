require 'easy_options_parser'

class TestEasyOptionsParser < EasyOptionsParser
  def set_argv(argv)
    @op.default_argv = argv
  end

  def has_exited_system?
    !!@system_exit_raised
  end

  def parse
    super
  rescue SystemExit
    @system_exit_raised = true
  end
end
