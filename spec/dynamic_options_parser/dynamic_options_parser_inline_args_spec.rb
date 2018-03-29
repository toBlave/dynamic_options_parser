require 'spec_helper'
require 'fileutils'
require 'byebug'

context DynamicOptionsParser, 'with inline initialisation args' do
  let(:help_args) do
    ["--help"]
  end

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

  context "add options" do
    before do
      @current_out = $stdout
      $stdout = output
    end

    after do
      $stdout = @current_out
    end

    context "the help text" do
      before do
        initialisation_args.merge!({option_1: [:string, "My first option"], option_2: [:array, "My second option"]})
        dynamic_options_parser.set_argv(help_args)
      end

      it "should accept the options and print the help option details" do
        dynamic_options_parser.parse
        expect(command_result).to match(/-h, --help\s+Prints this help/)
      end

      it "should have the option 1 details" do
        dynamic_options_parser.parse
        expect(command_result).to match(/-o, --option-1 OPTION_1\s+My first option/)
      end

      it "should have the option 2 details" do
        dynamic_options_parser.parse
        expect(command_result).to match(/-p, --option-2 OPTION_2\s+My second option/)
      end

      context "with a cli description set" do
        it "should print the cli description (1)" do
          dynamic_options_parser.cli_description = "The description for my script"
          dynamic_options_parser.parse

          expect(StringIO.new(command_result).readlines[0].strip).to match(/^The description for my script/)
        end

        it "should print the cli description (2)" do
          dynamic_options_parser.cli_description = "An alternate description for my script"
          dynamic_options_parser.parse

          expect(StringIO.new(command_result).readlines[0].strip).to match(/^An alternate description for my script/)
        end
      end
    end

    context "the parsed options" do
      context "where option name start with different characters" do
        before do
          initialisation_args.merge!({my_option: [:string, "My option"], your_option: [:string, "Your option"]})
        end


        context "where arguments are specified via single character switches" do
          before do
            dynamic_options_parser.set_argv([
              '-m',
              'Option 1',
              '-y',
              'Option 2'
            ])
          end

          it 'should set each option with based on the switch for the first character (-m)' do
            expect(parsed_options.my_option).to eq('Option 1')
          end

          it 'should set each option with based on the switch for the first character (-y)' do
            expect(parsed_options.your_option).to eq('Option 2')
          end
        end

        context "where arguments are specified via word switches" do
          before do
            dynamic_options_parser.set_argv([
              '--my-option',
              'Option 1',
              '--your-option',
              'Option 2'
            ])
          end

          it 'should set each option with based on the switch for the first character (-m)' do
            expect(parsed_options.my_option).to eq('Option 1')
          end

          it 'should set each option with based on the switch for the first character (-y)' do
            expect(parsed_options.your_option).to eq('Option 2')
          end
        end
      end

      context "where option name start with the same characters" do
        before do
          initialisation_args.merge!({my_option: [:string, "My option"], my_second_option: [:string, "Second option"], my_special_option: [:string, "Special option"]})
        end


        context "where arguments are specified via single character switches" do
          before do
            dynamic_options_parser.set_argv([
              '-m',
              'Option 1',
              '-y',
              'Option 2',
              '-s',
              'Option sp'
            ])
          end

          it 'should assign the first unique character in the option name to the option (my option)' do
            expect(parsed_options.my_option).to eq('Option 1')
          end

          it 'should set each option with based on the switch for the first character (my second option)' do
            expect(parsed_options.my_second_option).to eq('Option 2')
          end

          it 'should set each option with based on the switch for the first character (my special option)' do
            expect(parsed_options.my_special_option).to eq('Option sp')
          end
        end
      end

      context "where the assign to is set" do
        before do
          @assign_to = OpenStruct.new
          initialisation_args.merge!({my_option: [:string, "My option"], _assign_to: @assign_to})
          dynamic_options_parser.set_argv([
            '-mOption 1'
          ])
          dynamic_options_parser.parse
        end

        it "should assign the options to he assign to object" do
          expect(@assign_to.my_option).to eq('Option 1')
        end
      end

      context 'the option type' do
        context 'BigDecimal' do
          before do
            initialisation_args.merge!({my_option: [:big_decimal, "My option"]})
          end

          it 'should parse the value to a big decimal where set to a valid value' do
            dynamic_options_parser.set_argv([
              '-m2.45'
            ])

            expect(parsed_options.my_option.class).to eq(BigDecimal)
            expect(parsed_options.my_option.to_s('F')).to eq('2.45')
          end

          it 'should raise an invalid argument error when set to an invalid value' do
            dynamic_options_parser.set_argv([
              '-maxdcv'
            ])

            expect{dynamic_options_parser.parse}.to raise_error(ArgumentError)
          end
        end

        context 'Date' do
          before do
            initialisation_args.merge!({my_option: [:date, "My option"]})
          end

          it 'should parse the value to a date where set to a valid value' do
            dynamic_options_parser.set_argv([
              '-m2015-12-13'
            ])

            expect(parsed_options.my_option.class).to eq(Date)
            expect(parsed_options.my_option).to eq(Date.parse('2015-12-13'))
          end

          it 'should raise an invalid argument error when set to an invalid value' do
            dynamic_options_parser.set_argv([
              '-maxdcv'
            ])

            expect{dynamic_options_parser.parse}.to raise_error(ArgumentError)
          end
        end

        context 'DateTime' do
          before do
            initialisation_args.merge!({my_option: [:date_time, "My Option"]})
          end

          it 'should parse the value to a date_time where set to a valid value' do
            dynamic_options_parser.set_argv([
              '-m2015-12-13T15:00:00'
            ])

            expect(parsed_options.my_option.class).to eq(DateTime)
            expect(parsed_options.my_option).to eq(DateTime.parse('2015-12-13T15:00:00'))
          end

          it 'should raise an invalid argument error when set to an invalid value' do
            dynamic_options_parser.set_argv([
              '-maxdcv'
            ])

            expect{dynamic_options_parser.parse}.to raise_error(ArgumentError)
          end
        end

        context 'ReadFile' do
          before do
            @tmp_file = File.join(Dir.tmpdir, "tmp_dyn_options_spec_#{DateTime.now.strftime('%Y-%m-%d%H%M%S')}")
            initialisation_args.merge!({my_option: [:read_file, "My Option"]})
          end

          after do
            FileUtils.rm_f(@tmp_file)
          end

          it 'should parse the value to a read file where set to a valid value' do
            File.write(@tmp_file, ' ')
            dynamic_options_parser.set_argv([
              '-m',
              @tmp_file
            ])

            expect(parsed_options.my_option.class).to eq(DynamicOptionsParser::ReadFile)
            expect(parsed_options.my_option.path).to eq(@tmp_file)
          end

          it 'should raise an invalid argument error when no file exists at that path' do
            dynamic_options_parser.set_argv([
              '-m',
              @tmp_file
            ])

            expect{dynamic_options_parser.parse}.to raise_error(ArgumentError)
          end
        end

        context 'Array' do
          before do
            initialisation_args.merge!({my_option: [:array, "My Option"]})
          end

          it 'should parse the value to a read file where set to a valid value' do
            dynamic_options_parser.set_argv([
              '-m',
              "1,2,3,4"
            ])

            expect(parsed_options.my_option.class).to eq(Array)
            expect(parsed_options.my_option).to eq(%w[1 2 3 4])
          end

          context 'Symbol' do
            before do
              initialisation_args.merge!({my_option: [:symbol, "My Option"]})
            end

            it 'should parse the value to a read file where set to a valid value' do
              dynamic_options_parser.set_argv([
                '-m',
                "my_value"
              ])

              expect(parsed_options.my_option).to eq(:my_value)
            end
          end


          context 'Array sub type' do
            context 'ReadFile' do
              before do
                @tmp_file = File.join(Dir.tmpdir, "tmp_dyn_options_spec_#{DateTime.now.strftime('%Y-%m-%d%H%M%S')}")
                @tmp_file_2 = File.join(Dir.tmpdir, "tmp_dyn_options_spec_#{DateTime.now.strftime('%Y-%m-%d%H%M%S')}_2")
                initialisation_args.merge!({my_option: ['array:read_file', "My Option"]})
              end

              after do
                FileUtils.rm_f(@tmp_file)
                FileUtils.rm_f(@tmp_file_2)
              end

              before do
                File.write(@tmp_file, ' ')
                File.write(@tmp_file_2, ' ')
                dynamic_options_parser.set_argv([
                  '-m',
                  "#{@tmp_file},#{@tmp_file_2}"
                ])
              end

              it 'should parse the base value to an array' do
                expect(parsed_options.my_option.class).to eq(Array)
              end

              it 'should have 2 ReadFile instances in the array' do
                expect(parsed_options.my_option.collect{|i| i.class }).to eq([DynamicOptionsParser::ReadFile, DynamicOptionsParser::ReadFile])
              end

              it 'should assign each item in the cli option to the path of the read files' do
                expect(parsed_options.my_option.collect(&:path)).to eq([@tmp_file, @tmp_file_2])
              end

              it 'should raise an invalid argument error when file 1 does not existt' do
                FileUtils.rm_f(@tmp_file)

                expect{dynamic_options_parser.parse}.to raise_error(ArgumentError)
              end

              it 'should raise an invalid argument error when file 1 does not existt' do
                FileUtils.rm_f(@tmp_file_2)

                expect{dynamic_options_parser.parse}.to raise_error(ArgumentError)
              end
            end

            context 'BigDecimal' do
              let(:decimal_args) do
                "2.45,3.45"
              end

              before do
                dynamic_options_parser.set_argv([
                  "-m#{decimal_args}"
                ])

                initialisation_args.merge!({my_option: ['array:big_decimal', "My option"]})
              end

              it 'should parse the values to a big decimal array where set to a valid value' do
                expect(dynamic_options_parser.parse.my_option.collect(&:class)).to eq([BigDecimal, BigDecimal])
              end

              it 'should parse the values to the correct values specified on cli where set to a valid value' do
                expect(dynamic_options_parser.parse.my_option.collect{|v| v.to_s('F')}).to eq(%w[2.45 3.45])
              end

              context 'when first value is invalid' do
                let(:decimal_args) do
                  "aabb,3.45"
                end

                it 'should raise an error' do
                  expect{dynamic_options_parser.parse}.to raise_error(ArgumentError)
                end
              end

              context 'when second value is invalid' do
                let(:decimal_args) do
                  "2.45,xxcc"
                end

                it 'should raise an error' do
                  expect{dynamic_options_parser.parse}.to raise_error(ArgumentError)
                end
              end
            end
          end
        end
      end
    end
  end
end
