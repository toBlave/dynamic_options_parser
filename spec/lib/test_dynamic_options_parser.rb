require 'dynamic_options_parser'

class TestDynamicOptionsParser < DynamicOptionsParser
  def set_argv(argv)
    @op.default_argv = argv
  end

  def has_exited_system?
    !!@system_exit_raised
  end

  def parse
    begin
      super
    rescue SystemExit
      @system_exit_raised = true
    end
  end
end
