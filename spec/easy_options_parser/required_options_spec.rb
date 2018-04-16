require 'spec_helper'
require 'fileutils'
require 'byebug'

context EasyOptionsParser do
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

  let(:easy_options_parser) do
    TestEasyOptionsParser.new
  end

  context "add options" do
    context 'where one option is required' do
      before do
        easy_options_parser.add_option(:option_1, :string, "My first option", required: true)
        easy_options_parser.add_option(:option_2, :array, "My second option")
      end

      context 'when the required option has not been specified' do
        before do
          easy_options_parser.set_argv(['-p', "1,2"])
          easy_options_parser.parse
        end

        it 'should exit the runtime' do
          expect(easy_options_parser).to have_exited_system
        end

        it 'should output that the required field is missing' do
          easy_options_parser.parse
          expect(command_result).to match(/option_1 must be specified/)
        end

        it 'should output the help text' do
          easy_options_parser.parse
          expect(command_result).to match(/--help\s+Prints this help/)
        end
      end

      it 'should not exit if the required option has been specified' do
        easy_options_parser.set_argv(['-o', "required_option"])
        options = easy_options_parser.parse
        expect(easy_options_parser).not_to have_exited_system
        expect(options.option_1).to eq('required_option')
      end
    end

    context 'where more than one option is required' do
      before do
        easy_options_parser.add_option(:option_1, :string, "My first option", required: true)
        easy_options_parser.add_option(:option_2, :array, "My second option", required: true)
        easy_options_parser.add_option(:option_3, :big_decimal, "My third option", required: true)
        easy_options_parser.add_option(:option_4, :big_decimal, "My fourth option")
      end

      it 'should exit if one required option has not been specified' do
        easy_options_parser.set_argv(['-o', "required_string", '-t', '1.5', '-i', '23.4'])
        expect(easy_options_parser).not_to have_exited_system
      end

      context 'if two required options have not been specified' do
        before do
          easy_options_parser.set_argv(['-t', '1.5', '-i', '23.4'])
          easy_options_parser.parse
        end

        it 'exits the system' do
          expect(easy_options_parser).to have_exited_system
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
          easy_options_parser.set_argv(['-i', '23.4'])
          easy_options_parser.parse
        end

        it 'exits the system' do
          expect(easy_options_parser).to have_exited_system
        end

        it 'displays a message saying the the required fileds have not been specified' do
          expect(command_result).to match(/option_1, option_2 and option_3 must be specified/)
        end

        it 'displays the help text' do
          expect(command_result).to match(/--help\s+Prints this help/)
        end
      end

      it 'does not display reuqired options missing message is help option passed to cli (--help)' do
        easy_options_parser.set_argv(['--help'])
        easy_options_parser.parse
        expect(command_result).not_to match(/must be specified/)
      end

      it 'does not display reuqired options missing message is help option passed to cli (-h)' do
        easy_options_parser.set_argv(['-h'])
        easy_options_parser.parse
        expect(command_result).not_to match(/must be specified/)
      end
    end
  end
end
