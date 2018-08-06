# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'

context EasyOptionsParser do
  let(:help_args) do
    ['--help']
  end

  let(:output) do
    CaptureStdOut.new
  end

  let(:command_result) do
    output.string
  end

  let(:easy_options_parser) do
    TestEasyOptionsParser.new
  end

  let(:parsed_options) do
    easy_options_parser.parse
  end

  context 'add options' do
    before do
      @current_out = $stdout
      $stdout = output
    end

    after do
      $stdout = @current_out
    end

    context 'the help text' do
      before do
        easy_options_parser.add_option(:option_1, :string, 'My first option')
                           .add_option(:option_2, :array, 'My second option',
                                       required: true)
                           .add_option(:option_3, :string, 'My third option',
                                       default: 'third_default')
        easy_options_parser.argv = ['-h']
      end

      it 'should accept the options and print the help option details' do
        easy_options_parser.parse
        expect(command_result).to match(/-h, --help\s+Prints this help/)
      end

      it 'should have the option 1 details' do
        easy_options_parser.parse
        expect(command_result).to match(
          /-o, --option-1 OPTION_1\s+My first option/
        )
      end

      it 'should have the option 2 details' do
        easy_options_parser.parse
        expect(command_result).to match(
          /-p, --option-2 OPTION_2\s+My second option/
        )
      end

      context 'with a cli description set' do
        let(:first_line_of_ouput) do
          StringIO.new(command_result).readlines[0].strip
        end

        it 'should print the cli description (1)' do
          easy_options_parser.cli_description = 'The description for my script'
          easy_options_parser.parse

          expect(first_line_of_ouput).to match(/^The description for my script/)
        end

        it 'should print the cli description (2)' do
          easy_options_parser.cli_description = 'Other description for script'
          easy_options_parser.parse

          expect(first_line_of_ouput).to match(/^Other description for script/)
        end
      end
    end

    context 'the parsed options' do
      context 'where option name start with different characters' do
        before do
          easy_options_parser.add_option(:my_option, :string, 'My option')
          easy_options_parser.add_option(:your_option, :string, 'Your option')
        end

        context 'where arguments are specified via single character switches' do
          before do
            easy_options_parser.argv = [
              '-m',
              'Option 1',
              '-y',
              'Option 2'
            ]
          end

          it 'sets options based on the switch for the first character (-m)' do
            expect(parsed_options.my_option).to eq('Option 1')
          end

          it 'sets option based on the switch for the first character (-y)' do
            expect(parsed_options.your_option).to eq('Option 2')
          end
        end

        context 'where arguments are specified via word switches' do
          before do
            easy_options_parser.argv = [
              '--my-option',
              'Option 1',
              '--your-option',
              'Option 2'
            ]
          end

          it 'sets options based on switch for full name (--my-option)' do
            expect(parsed_options.my_option).to eq('Option 1')
          end

          it 'sets options based on switch for full name (--your-option)' do
            expect(parsed_options.your_option).to eq('Option 2')
          end
        end
      end

      context 'where option name start with the same characters' do
        before do
          easy_options_parser.add_option(:my_option, :string, 'My option')
          easy_options_parser.add_option(:my_second_option, :string,
                                         'Second option')
          easy_options_parser.add_option(:my_special_option, :string,
                                         'Special option')
        end

        context 'where arguments are specified via single character switches' do
          before do
            easy_options_parser.argv = [
              '-m',
              'Option 1',
              '-y',
              'Option 2',
              '-s',
              'Option sp'
            ]
          end

          it 'accepts first unique character as switch (my option)' do
            expect(parsed_options.my_option).to eq('Option 1')
          end

          it 'accepts first unique character as switch (my second option)' do
            expect(parsed_options.my_second_option).to eq('Option 2')
          end

          it 'accepts first unique character as switch (my special option)' do
            expect(parsed_options.my_special_option).to eq('Option sp')
          end
        end
      end

      context 'where the assign to is set' do
        before do
          @assign_to = OpenStruct.new
          easy_options_parser.add_option(:my_option, :string, 'My option')
          easy_options_parser.assign_to(@assign_to)
          easy_options_parser.argv = [
            '-mOption 1'
          ]
          easy_options_parser.parse
        end

        it 'should assign the options to he assign to object' do
          expect(@assign_to.my_option).to eq('Option 1')
        end
      end

      context 'the option type' do
        context 'BigDecimal' do
          it 'parses the value to a big decimal where set to a valid value' do
            easy_options_parser.add_option(:my_option, :big_decimal,
                                           'My option')
            easy_options_parser.argv = [
              '-m2.45'
            ]

            expect(parsed_options.my_option.class).to eq(BigDecimal)
            expect(parsed_options.my_option.to_s('F')).to eq('2.45')
          end

          it 'raises an invalid argument error when set to an invalid value' do
            easy_options_parser.add_option(:my_option, :big_decimal,
                                           'My option')
            easy_options_parser.argv = [
              '-maxdcv'
            ]

            expect { easy_options_parser.parse }.to raise_error(ArgumentError)
          end
        end

        context 'dirglob' do
          let(:dirglob) do
            'my_dirs*'
          end

          let(:glob_result) do
            ['/tmp/file_1', '/tmp/file_2']
          end

          before do
            easy_options_parser.add_option(:my_option, :dir_glob, 'My option')

            expect(Dir).to receive(:glob).with(dirglob).and_return(glob_result)
          end

          it 'should parse the value to a date where set to a valid value' do
            easy_options_parser.argv = [
              "-m#{dirglob}"
            ]

            expect(parsed_options.my_option).to eq(
              ['/tmp/file_1', '/tmp/file_2']
            )
          end
        end

        context 'Date' do
          before do
            easy_options_parser.add_option(:my_option, :date, 'My option')
          end

          it 'assigns value to a date where set to a valid value' do
            easy_options_parser.argv = [
              '-m2015-12-13'
            ]

            expect(parsed_options.my_option.class).to eq(Date)
            expect(parsed_options.my_option).to eq(Date.parse('2015-12-13'))
          end

          it 'raises an invalid argument error when set to an invalid value' do
            easy_options_parser.argv = [
              '-maxdcv'
            ]

            expect { easy_options_parser.parse }.to raise_error(ArgumentError)
          end
        end

        context ':read_file' do
          before do
            @tmp_file = File.join(
              Dir.tmpdir,
              "tmp_dyn_options_spec_#{Time.current.strftime('%Y-%m-%d%H%M%S')}"
            )
            easy_options_parser.add_option(:my_option, :read_file, 'My option')
          end

          after do
            FileUtils.rm_f(@tmp_file)
          end

          it 'assigns the value to a read file where set to a valid value' do
            File.write(@tmp_file, ' ')
            easy_options_parser.argv = [
              '-m',
              @tmp_file
            ]

            expect(parsed_options.my_option.class).to eq(String)
            expect(parsed_options.my_option).to eq(@tmp_file)
          end

          it 'raises an invalid argument error when file does not exists' do
            easy_options_parser.argv = [
              '-m',
              @tmp_file
            ]

            expect { easy_options_parser.parse }
              .to raise_error("Path #{@tmp_file} does not exist")
          end
        end

        context 'Time' do
          before do
            easy_options_parser.add_option(:my_option, :time, 'My Option')
          end

          it 'parses the value to a date_time where set to a valid value' do
            easy_options_parser.argv = [
              '-m2015-12-13T15:00:00'
            ]

            expect(parsed_options.my_option.class).to eq(Time)
            expect(parsed_options.my_option).to eq(
              Time.parse('2015-12-13T15:00:00')
            )
          end

          it 'raises an invalid argument error when set to an invalid value' do
            easy_options_parser.argv = [
              '-maxdcv'
            ]

            expect { easy_options_parser.parse }.to raise_error(ArgumentError)
          end
        end

        context 'dir' do
          before do
            @tmp_file = File.join(
              Dir.tmpdir,
              "tmp_dyn_options_spec_#{Time.now.strftime('%Y-%m-%d%H%M%S')}"
            )
            easy_options_parser.add_option(:my_option, :dir, 'My Option')
            easy_options_parser.argv = ['-m', @tmp_file]
          end

          after do
            FileUtils.rm_rf(@tmp_file)
          end

          it 'raises an error where the path does not exist' do
            expect { easy_options_parser.parse }
              .to raise_error "Path #{@tmp_file} does not exist"
          end

          it 'raises an error where the path exists but is not a directory' do
            File.write(@tmp_file, ' ')
            expect { easy_options_parser.parse }
              .to raise_error "Path #{@tmp_file} exists but is not a directory"
          end

          it 'assigns value to a string when path is an existing directory' do
            FileUtils.mkdir_p(@tmp_file)
            expect(easy_options_parser.parse.my_option).to eq(@tmp_file)
          end
        end

        context 'Array' do
          before do
            easy_options_parser.add_option(:my_option, :array, 'My Option')
          end

          it 'parses the value to an array' do
            easy_options_parser.argv = [
              '-m',
              '1,2,3,4'
            ]

            expect(parsed_options.my_option.class).to eq(Array)
            expect(parsed_options.my_option).to eq(%w[1 2 3 4])
          end
        end

        context 'Symbol' do
          before do
            easy_options_parser.add_option(:my_option, :symbol, 'My Option')
          end

          it 'parses the value to a symbol' do
            easy_options_parser.argv = [
              '-m',
              'my_value'
            ]

            expect(parsed_options.my_option).to eq(:my_value)
          end
        end

        context 'Boolean' do
          before do
            easy_options_parser.add_option(:my_option, :boolean, 'My Option')
          end

          it 'parses the value to a true boolean is set to true' do
            easy_options_parser.argv = [
              '-m',
              'true'
            ]

            expect(parsed_options.my_option).to eq(true)
          end

          it 'parses the value to a false boolean is set to false' do
            easy_options_parser.argv = [
              '-m',
              'false'
            ]

            expect(parsed_options.my_option).to eq(false)
          end

          it 'parses the value to a TRUE boolean is set to TRUE' do
            easy_options_parser.argv = [
              '-m',
              'TRUE'
            ]

            expect(parsed_options.my_option).to eq(true)
          end

          it 'parses the value to a FALSE boolean is set to FALSE' do
            easy_options_parser.argv = [
              '-m',
              'FALSE'
            ]

            expect(parsed_options.my_option).to eq(false)
          end

          it 'parses the value to a true boolean is set to t' do
            easy_options_parser.argv = [
              '-m',
              't'
            ]

            expect(parsed_options.my_option).to eq(true)
          end

          it 'parses the value to a false boolean is set to f' do
            easy_options_parser.argv = [
              '-m',
              'f'
            ]

            expect(parsed_options.my_option).to eq(false)
          end

          it 'parses the value to a true boolean is set to T' do
            easy_options_parser.argv = [
              '-m',
              'T'
            ]

            expect(parsed_options.my_option).to eq(true)
          end

          it 'parses the value to a false boolean is set to F' do
            easy_options_parser.argv = [
              '-m',
              'F'
            ]

            expect(parsed_options.my_option).to eq(false)
          end

          it 'parses the value to a true boolean is set to 1' do
            easy_options_parser.argv = [
              '-m',
              '1'
            ]

            expect(parsed_options.my_option).to eq(true)
          end

          it 'parses the value to a false boolean is set to 0' do
            easy_options_parser.argv = [
              '-m',
              '0'
            ]

            expect(parsed_options.my_option).to eq(false)
          end

          it 'raises an error if set to anything other value' do
            easy_options_parser.argv = [
              '-m',
              'whatever'
            ]

            expect { parsed_options }
              .to raise_error('Invalid boolean value "whatever"')
          end
        end

        context 'Array sub type' do
          context 'read_file' do
            before do
              @tmp_file = File.join(
                Dir.tmpdir,
                "tmp_dyn_options_spec_#{Time.now.strftime('%Y-%m-%d%H%M%S')}"
              )

              @tmp_file2 = File.join(
                Dir.tmpdir,
                "tmp_dyn_options_spec_#{Time.now.strftime('%Y-%m-%d%H%M%S')}_2"
              )
              easy_options_parser.add_option(
                :my_option,
                'array:read_file',
                ' Option'
              )
            end

            after do
              FileUtils.rm_f(@tmp_file)
              FileUtils.rm_f(@tmp_file2)
            end

            before do
              File.write(@tmp_file, ' ')
              File.write(@tmp_file2, ' ')
              easy_options_parser.argv = [
                '-m',
                "#{@tmp_file},#{@tmp_file2}"
              ]
            end

            it 'should parse the base value to an array' do
              expect(parsed_options.my_option.class).to eq(Array)
            end

            it 'should have 2 ReadFile instances in the array' do
              expect(parsed_options.my_option.collect(&:class)).to eq(
                [String, String]
              )
            end

            it 'assigns each item in the cli option to strings' do
              expect(parsed_options.my_option).to eq([@tmp_file, @tmp_file2])
            end

            it 'raises an invalid argument error when file 1 does not exist' do
              FileUtils.rm_f(@tmp_file)

              expect { easy_options_parser.parse }.to raise_error(
                "Path #{@tmp_file} does not exist"
              )
            end

            it 'raises an invalid argument error when file 2 does not exist' do
              FileUtils.rm_f(@tmp_file2)

              expect { easy_options_parser.parse }.to raise_error(
                "Path #{@tmp_file2} does not exist"
              )
            end
          end

          context 'BigDecimal' do
            let(:decimal_args) do
              '2.45,3.45'
            end

            before do
              easy_options_parser.argv = [
                "-m#{decimal_args}"
              ]

              easy_options_parser.add_option(
                :my_option, 'array:big_decimal', 'My option'
              )
            end

            it 'parses options to big decimals where set to a valid value' do
              classes = easy_options_parser.parse.my_option.collect(&:class)

              expect(classes).to eq(
                [BigDecimal, BigDecimal]
              )
            end

            it 'parses the option to the correct values where set to valid' do
              parsed_values = easy_options_parser.parse.my_option.collect do |v|
                v.to_s('F')
              end

              expect(parsed_values).to eq(%w[2.45 3.45])
            end

            context 'when first value is invalid' do
              let(:decimal_args) do
                'aabb,3.45'
              end

              it 'should raise an error' do
                expect { easy_options_parser.parse }
                  .to raise_error(ArgumentError)
              end
            end

            context 'when second value is invalid' do
              let(:decimal_args) do
                '2.45,xxcc'
              end

              it 'should raise an error' do
                expect { easy_options_parser.parse }
                  .to raise_error(ArgumentError)
              end
            end
          end
        end
      end
    end
  end
end
