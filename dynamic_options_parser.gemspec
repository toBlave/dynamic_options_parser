Gem::Specification.new do |s|
  s.name        = 'dynamic_options_parser'
  s.version     = '0.1.0'
  s.date        = '2017-12-19'
  s.summary     = "A wrapper for standard ruby OptionParser to make it easier to define and interpet command line options"
  s.description = "Dynamic Option Parser - A wrapper around ruby's OptionParser"
  s.authors     = ["Steve Vanspall"]
  s.email       = 'steve@vanspall.id.au'
  s.files       = ["lib/dynamic_options_parser.rb"]
  s.add_dependency "activesupport"
  s.add_development_dependency "rspec"
  s.add_development_dependency "byebug"
  s.license       = 'MIT'
end
