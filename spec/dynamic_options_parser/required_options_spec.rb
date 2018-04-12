require 'spec_helper'
require 'fileutils'
require 'byebug'

context DynamicOptionsParser do
  let(:output) do
    StringIO.new
  end

  before do
    @original_stdio = $stdout
    $stdout = output
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

      context 'when the required option has not been specified' do
        before do
          dynamic_options_parser.set_argv(['-p', "1,2"])
          dynamic_options_parser.parse
        end

        it 'should exit the runtime' do
          expect(dynamic_options_parser).to have_exited_system
        end

        it 'should output that the required field is missing' do
          dynamic_options_parser.parse
          expect(command_result).to match(/option_1 must be specified/)
        end

        it 'should output the help text' do
          dynamic_options_parser.parse
          expect(command_result).to match(/--help\s+Prints this help/)
        end
      end

      it 'should not exit if the required option has been specified' do
        dynamic_options_parser.set_argv(['-o', "required_option"])
        options = dynamic_options_parser.parse
        expect(dynamic_options_parser).not_to have_exited_system
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

      it 'should exit if one required option has not been specified' do
        dynamic_options_parser.set_argv(['-o', "required_string", '-t', '1.5', '-i', '23.4'])
        expect(dynamic_options_parser).not_to have_exited_system
      end

      context 'if two required options have not been specified' do
        before do
          dynamic_options_parser.set_argv(['-t', '1.5', '-i', '23.4'])
          dynamic_options_parser.parse
        end

        it 'exits the system' do
          expect(dynamic_options_parser).to have_exited_system
        end

        it 'displays a message saying that the required options are missing' do
          expect(command_result).to match(/option_1 and option_2 must be specified/)
        end

        it 'displays the help information' do
          expect(command_result).to match(/--help\s+Prints this help/)
        end
      end

      context 'if three or more required options have not been specified' do
        before do
          dynamic_options_parser.set_argv(['-i', '23.4'])
          dynamic_options_parser.parse
        end

        it 'exits the system' do
          expect(dynamic_options_parser).to have_exited_system
        end

        it 'displays a message saying the the required fileds have not been specified' do
          expect(command_result).to match(/option_1, option_2 and option_3 must be specified/)
        end

        it 'displays the help text' do
          expect(command_result).to match(/--help\s+Prints this help/)
        end
      end

      it 'does not display reuqired options missing message is help option passed to cli (--help)' do
        dynamic_options_parser.set_argv(['--help'])
        dynamic_options_parser.parse
        expect(command_result).not_to match(/must be specified/)
      end

      it 'does not display reuqired options missing message is help option passed to cli (-h)' do
        dynamic_options_parser.set_argv(['-h'])
        dynamic_options_parser.parse
        expect(command_result).not_to match(/must be specified/)
      end
    end
  end
end
