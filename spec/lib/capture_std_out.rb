# frozen_string_literal: true

class CaptureStdOut < StringIO
  attr_reader :capture_io

  def initialize
    super
  end

  def write(string)
    super
    STDOUT.write(string)
  end
end
