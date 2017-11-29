require 'spec_helper'
require 'fileutils'
require 'byebug'

context DynamicOptionsParser do
  let(:output) do
    StringIO.new
  end

  let(:command_result) do
    output.string
  end

  let(:dynamic_options_parser) do
    TestDynamicOptionsParser.new(initialisation_args)
  end

  let(:parsed_options) do
    dynamic_options_parser.parse
  end

  let(:initialisation_args) do
    {}
  end

  let(:argv) do
    []
  end

  context "add options" do
    before do
      @current_out = $stdout
      $stdout = output
    end

    after do
      $stdout = @current_out
    end

    context "with inline arguments" do
      before do
        initialisation_args.merge!({
          option_1: [:string, "My first option", "My Default 1"], 
          option_2: [:array, "My second option", [:option_2_default]], 
          option_3: [:date_time, "My third option", DateTime.parse('2011-12-12T15:00:00')]
        })
      end

      it "should set the default for any value that is not set" do 
        dynamic_options_parser.set_argv(argv)

        expect(parsed_options.option_1).to eq("My Default 1")
        expect(parsed_options.option_3).to eq(DateTime.parse('2011-12-12T15:00:00'))
        expect(parsed_options.option_2).to eq([:option_2_default])
      end

      it "should allow override when any value is set on command line and default other values" do
        argv << ['-o', 'Option 1 Value', '-t', '2015-12-24T16:35:00']
        argv.flatten!
        dynamic_options_parser.set_argv(argv)

        expect(parsed_options.option_1).to eq("Option 1 Value")
        expect(parsed_options.option_2).to eq([:option_2_default])
        expect(parsed_options.option_3).to eq(DateTime.parse('2015-12-24T16:35:00'))
      end
    end

    context "with options added spearately" do
      before do
        dynamic_options_parser.
          add_option(:option_1, :string, "My first option", "My Default 1"). 
          add_option(:option_2, :array, "My second option", [:option_2_default]).
          add_option(:option_3, :date_time, "My third option", DateTime.parse('2011-12-12T15:00:00'))
      end

      it "should set the default for any value that is not set" do 
        dynamic_options_parser.set_argv(argv)

        expect(parsed_options.option_1).to eq("My Default 1")
        expect(parsed_options.option_3).to eq(DateTime.parse('2011-12-12T15:00:00'))
        expect(parsed_options.option_2).to eq([:option_2_default])
      end

      it "should allow override when any value is set on command line and default other values" do
        argv << ['-o', 'Option 1 Value', '-t', '2015-12-24T16:35:00']
        argv.flatten!
        dynamic_options_parser.set_argv(argv)

        expect(parsed_options.option_1).to eq("Option 1 Value")
        expect(parsed_options.option_2).to eq([:option_2_default])
        expect(parsed_options.option_3).to eq(DateTime.parse('2015-12-24T16:35:00'))
      end
    end
  end
end
