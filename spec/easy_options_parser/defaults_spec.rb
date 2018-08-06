# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'byebug'

context EasyOptionsParser do
  let(:output) do
    CaptureStdOut.new
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

  context 'add options' do
    before do
      @current_out = $stdout
      $stdout = output
    end

    after do
      $stdout = @current_out
    end

    before do
      easy_options_parser
        .add_option(:option_1, :string, 'My first option',
                    default: 'My Default 1')
        .add_option(:option_2, :array, 'My second option',
                    default: [:option_2_default])
        .add_option(:option_3, :time, 'My third option',
                    default: Time.parse('2011-12-12T15:00:00'))
    end

    it 'should set the default for any value that is not set' do
      easy_options_parser.argv = argv

      expect(parsed_options.option_1).to eq('My Default 1')
      expect(parsed_options.option_3).to eq(
        Time.parse('2011-12-12T15:00:00')
      )
      expect(parsed_options.option_2).to eq([:option_2_default])
    end

    it 'allows user to override when defaults via command line switches' do
      argv << ['-o', 'Option 1 Value', '-t', '2015-12-24T16:35:00']
      argv.flatten!
      easy_options_parser.argv = argv

      expect(parsed_options.option_1).to eq('Option 1 Value')
      expect(parsed_options.option_2).to eq([:option_2_default])
      expect(parsed_options.option_3).to eq(
        Time.parse('2015-12-24T16:35:00')
      )
    end
  end
end
