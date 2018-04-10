require 'spec_helper'
require 'fileutils'

context DynamicOptionsParser do
  let(:output) do
    StringIO.new
  end

  before do
    @original_stdio = $stdout
    $stdout = StringIO.new
  end

  after do
    $stdout = @original_stdio
  end

  let(:command_result) do
    output.string
  end

  let(:dynamic_options_parser) do
    TestDynamicOptionsParser.new
  end

  context "add options" do
    context 'where one option is required' do
      before do
        dynamic_options_parser.add_option(:option_1, :string, "My first option", required: true)
        dynamic_options_parser.add_option(:option_2, :array, "My second option")
      end

      it 'should raise an error if the required option has not been specified' do
        dynamic_options_parser.set_argv(['-p', "1,2"])
        expect { dynamic_options_parser.parse }.to raise_error 'option_1 must be specified, use --help for options'
      end

      it 'should not raise an error if the required option has been specified' do
        dynamic_options_parser.set_argv(['-o', "required_option"])
        options = nil
        expect { options = dynamic_options_parser.parse }.not_to raise_error
        expect(options.option_1).to eq('required_option')
      end
    end

    context 'where more than one option is required' do
      before do
        dynamic_options_parser.add_option(:option_1, :string, "My first option", required: true)
        dynamic_options_parser.add_option(:option_2, :array, "My second option", required: true)
        dynamic_options_parser.add_option(:option_3, :big_decimal, "My third option", required: true)
        dynamic_options_parser.add_option(:option_4, :big_decimal, "My fourth option")
      end

      it 'should raise an error if one required option has not been specified' do
        dynamic_options_parser.set_argv(['-o', "required_string", '-t', '1.5', '-i', '23.4'])
        expect { dynamic_options_parser.parse }.to raise_error 'option_2 must be specified, use --help for options'
      end

      it 'should raise an error if two required options have not been specified' do
        dynamic_options_parser.set_argv(['-t', '1.5', '-i', '23.4'])
        expect { dynamic_options_parser.parse }.to raise_error 'option_1 and option_2 must be specified, use --help for options'
      end

      it 'should raise an error if three or more required options have not been specified' do
        dynamic_options_parser.set_argv(['-i', '23.4'])
        expect { dynamic_options_parser.parse }.to raise_error 'option_1, option_2 and option_3 must be specified, use --help for options'
      end

      it 'should not raise an error if help argument passed (--help)' do
        dynamic_options_parser.set_argv(['--help'])

        expect { dynamic_options_parser.parse }.not_to raise_error
      end

      it 'should not raise an error if help argument passed (-h)' do
        dynamic_options_parser.set_argv(['-h'])

        expect { dynamic_options_parser.parse }.not_to raise_error
      end
    end
  end
end
