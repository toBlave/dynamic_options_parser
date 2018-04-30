require 'spec_helper'
require 'fileutils'
require 'byebug'

context EasyOptionsParser do
  let(:output) do
    StringIO.new
  end

  let(:command_result) do
    output.string
  end

  let(:easy_options_parser) do
    TestEasyOptionsParser.new(initialisation_args)
  end

  context 'when assign to is set to an object' do
    before do
      @current_out = $stdout
      $stdout = output
    end

    after do
      $stdout = @current_out
    end

    let(:assign_to) do
      OptionsAssignTo.new
    end

    before do
      easy_options_parser
        .add_option(:option_1, :string, 'My first option')
        .add_option(:option_2, :array, 'My second option', default: [:option_2_default])
        .add_option(:option_3, :date_time, 'My third option')
    end

    describe 'when assign_to set via the assign_to method' do
      let(:initialisation_args) do
        {}
      end

      before do
        easy_options_parser.assign_to(assign_to)
      end

      it 'should set any set options onto the assign_to object' do
        easy_options_parser.set_argv(['--option-1', 'Option Value 1',
                                      '--option-2', '1,2,3,4',
                                      '--option-3', '2011-12-12T15:00:00'])

        easy_options_parser.parse
        expect(assign_to.option_1).to eq('Option Value 1')
        expect(assign_to.option_2).to eq(%w[1 2 3 4])
        expect(assign_to.option_3).to eq(DateTime.parse('2011-12-12T15:00:00'))
      end

      it 'should set defaults where a default value is available and the option is not set' do
        easy_options_parser.set_argv([])

        easy_options_parser.parse
        expect(assign_to.option_2).to eq([:option_2_default])
      end

      it 'should leave all blank values blank if not defaulted and not set' do
        easy_options_parser.set_argv([])

        easy_options_parser.parse
        expect(assign_to.option_1).to be_nil
        expect(assign_to.option_3).to be_nil
      end

      it 'should still exit with a message if a required option is not set' do
        easy_options_parser.add_option(:option_4, :string, 'My Fourth Option', required: true)
        easy_options_parser.set_argv([])

        easy_options_parser.parse
        expect(easy_options_parser).to have_exited_system
        expect(command_result).to match(/--option-4 must be specified/)
      end
    end

    describe 'when assign_to passed into constructor' do
      let(:initialisation_args) do
        { _assign_to: assign_to }
      end

      it 'should set any set options onto the assign_to object' do
        easy_options_parser.set_argv(['--option-1', 'Option Value 1',
                                      '--option-2', '1,2,3,4',
                                      '--option-3', '2011-12-12T15:00:00'])

        easy_options_parser.parse
        expect(assign_to.option_1).to eq('Option Value 1')
        expect(assign_to.option_2).to eq(%w[1 2 3 4])
        expect(assign_to.option_3).to eq(DateTime.parse('2011-12-12T15:00:00'))
      end

      it 'should set defaults where a default value is available and the option is not set' do
        easy_options_parser.set_argv([])

        easy_options_parser.parse
        expect(assign_to.option_2).to eq([:option_2_default])
      end

      it 'should leave all blank values blank if not defaulted and not set' do
        easy_options_parser.set_argv([])

        easy_options_parser.parse
        expect(assign_to.option_1).to be_nil
        expect(assign_to.option_3).to be_nil
      end

      it 'should still exit with a message if a required option is not set' do
        easy_options_parser.add_option(:option_4, :string, 'My Fourth Option', required: true)
        easy_options_parser.set_argv([])

        easy_options_parser.parse
        expect(easy_options_parser).to have_exited_system
        expect(command_result).to match(/--option-4 must be specified/)
      end
    end
  end
end
