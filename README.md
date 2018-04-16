# Easy Options Parser
 
This is a wrapper around the standard Ruby OptionsParser. It's designed to make it easier to declare command line options for Command Line ruby scripts.

## Usage
``` ruby
require 'easy_options_parser'

options_parser = EasyOptionsParser.new
options_parser.add_option(:input_file, :read_file, "Input File to read into system")
              .add_option(:ouput_file, :string, "Output File to read into system")
cli_options = options_parser.parse
```

If this code is included in a ruby script, you can now include command line options when running the script. In this case the accepted options would be:

 - --input-file which accepts a read_file (see Option Types for details on read_file)
 - --output-file which accepts a string
 
 These options are set to the ```input_file``` and ```output_file``` methods on the object returned by calling ```parse```
 
In addition to this calling the script with ```--help``` will print a list of available options. 
```
Usage: ruby my_script.rb [options]
    -h, --help                       Prints this help
    -i, --input-file INPUT_FILE      Input File to read into system
    -o, --ouput-file OUPUT_FILE      Output File to read into system
```
Calling parse return an object with the methods input_file and output_file. These will be set to whatever was passed in for that option from the Command Line

## Required and default options
In addition to adding options, you can set a default and mark them as required

```ruby
options_parser = EasyOptionsParser.new
options_parser.add_option(:input_file, :read_file, "Input File to read into system", required: true)
              .add_option(:ouput_file, :string, "Output File to read into system", default: './out_file')
```
This will set the default output file to ./out_file if not overridden on the command line
This will exit and show a message taht input_file is required if it is not supplied on the command line

## Option Types

The second argument of the add_option method is an option_type. This string or symbol with be transformed into a class name, :time to Time, :float to Float, :array to Array.

As such this library can handle any of the types supported by the standard OptionParser class in ruby. See https://docs.ruby-lang.org/en/2.5.0/OptionParser.html for more information. 

In addition to this there are other option type that are supported

```:read_file``` - This evaluates to a string. It expects the file path of an existing file. It will validate that the file exists and throw an error if it doesn't. This provides an easy way to ensure the ruby script is called with an existing file path.

```:dir``` - Similar to :read_file but also validates that the path provided is a directory

```:boolean``` - Will convert ```true```, ```false```, ```TRUE```, ```FALSE```, ```t```,```f```,```T```,```F``` to boolean true and boolean false respectively

```:big_decimal``` - Will convert option to a BigDecimal

```:date_time``` - Will parse option as a date_time. Accepts anything DateTime.parse accepts

```:time``` - Will parse option as a Time. Accepts anything Time.parse accepts

```:date``` - Will parse option as a Data. Accepts anything Date.parse accepts

## Shorthand option flags

In addition to ``--input-file myFile`` with the option added above you could also user ```-i myFile```

Currently this gem auto-assigns the shorthand option flag by finding the first letter in the option name that has not already been used.

```ruby
require 'easy_options_parser'

options_parser = EasyOptionsParser.new
options_parser.add_option(:option_1, :read_file, "Input File to read into system")
              .add_option(:option_2, :string, "Output File to read into system")
              .add_option(:option_3, :dir, "The directory we want to use")
cli_options = options_parser.parse
```

Would assign ```-o``` to ```option_1``` ```-p``` to ```option_2``` and ```-t``` to ```option_3```

If in doubt, once you've added this to your code you can run the scripts with ```--help``` to see the resulting options

``` 
Usage: ruby my_script.rb [options]
    -h, --help                       Prints this help
    -o, --option-1 OPTION_1          Input File to read into system
    -p, --option-2 OPTION_2          Output File to read into system
    -t, --option-3 OPTION_3          The directory we want to use
```

## TODO

- Allow override of shorthand option
- Refactoring needed to make this easier to extend with other new option_types
- Remove open_struct as base object
- Document assign_to (let's you set the object you what the options to be set on)
- Document overriding description line when showing help text
