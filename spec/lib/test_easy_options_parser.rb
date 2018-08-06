# frozen_string_literal: true

require 'easy_options_parser'

class TestEasyOptionsParser < EasyOptionsParser
  def argv=(argv)
    @op.default_argv = argv
  end

  def has_exited_system?
    !@system_exit_raised.nil?
  end

  def parse
    super
  rescue SystemExit
    @system_exit_raised = true
  end
end
