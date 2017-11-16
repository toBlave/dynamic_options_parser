# This is a wrpper around the standard Ruby OptionsParser. It's designed to make it easier to declare command line options for Command Line ruby scripts.

# Usage
``` ruby
require 'dynamic_options_parser'

options_parser = DynamicOptionsParser.new
options_parser.add_option(:input_file, :string, "Input File to read into system")
options_parser.add_option(:ouput_file, :string, "Output File to read into system")
cli_options = options_parser.parse
```

If this code is included in a ruby script, you can now include command line options when running the script. In this case the accpeted options would be:

--input-file which accepts a string
--output-file which also accepts a string

In addition to this calling the script with --help will print a list of available options. 

Calling parse return an object with the methods input_file and output_file. These will be set to whatever was passed in for that option from the Command Line

RDOC and more examples to come
