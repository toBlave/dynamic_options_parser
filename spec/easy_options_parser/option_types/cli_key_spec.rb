require 'spec_helper'
require 'fileutils'
require 'byebug'

describe EasyOptionsParser do
    let(:output) do
    StringIO.new
  end

  let(:command_result) do
    output.string
  end

  let(:easy_options_parser) do
    TestEasyOptionsParser.new(initialisation_args)
  end

  let(:parsed_options) do
    easy_options_parser.parse
  end

  let(:initialisation_args) do
    {}
  end

  let(:argv) do
    []
  end

  describe 'cli_key' do
    it 'should request a cli key based on the description' do

    end
  end
end