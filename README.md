# This is a wrpper around the standard Ruby OptionsParser. It's designed to make it easier to declare command line options for Command Line ruby scripts.

# Usage
``` ruby
require 'dynamic_options_parser'

options_parser = DynamicOptionsParser.new
options_parser.add_option(:input_file, :read_file, "Input File to read into system")
              .add_option(:ouput_file, :string, "Output File to read into system")
cli_options = options_parser.parse
```

If this code is included in a ruby script, you can now include command line options when running the script. In this case the accpeted options would be:

--input-file which accepts a read_file (see below) 
--output-file which accepts a string

In addition to this calling the script with --help will print a list of available options. 

Calling parse return an object with the methods input_file and output_file. These will be set to whatever was passed in for that option from the Command Line

In addition to adding options, you can set a default and marke them as required

options_parser = DynamicOptionsParser.new
options_parser.add_option(:input_file, :read_file, "Input File to read into system", required: true)
              .add_option(:ouput_file, :string, "Output File to read into system", default: './out_file')

This will set the default output file to ./out_file if not overridden on the command line
This will exit and show a message taht input_file is required if it is not supplied on the command line

# Option Types

The second argument of the add_option method is an option_type. This string or symbol with be transformed into a class name, :time to Time, :float to Float, :array to Array.

As such this library can handle any of the types supported by the standard OptionParser class in ruby. See https://docs.ruby-lang.org/en/2.5.0/OptionParser.html for more information. 

In addition to this there are other option type that are supported

:read_file - This evaluates to a string. It expects the file path of an existing file. It will validate that the file exists and throw an error if it doesn't. This provides an easy way to ensure the ruby script is called with an existing file path.

:dir - Similar to :read_file but also validates that the path provided is a directory

:boolean - Will convert true, false, TRUE, FALSE, t, f to boolean true and boolean false respectively

:big_decimal - Will convert option to a BigDecimal

:date_time - Will parse option as a date_time. Accepts anything DateTime.parse accepts

:time - Will parse option as a Time. Accepts anything Time.parse accepts

:date - Will parse option as a Data. Accepts anything Date.parse accepts

:symbol - Will convert option to a symbol

'array:n' - Allows specification of the type of objects an array should have. 'array:big_decimal' will convert option to an array of BigDecimal objects. As for OptionParser arrays values need to be specified as a comma separated string of values. eg: "1.0,2.45,3.3"
