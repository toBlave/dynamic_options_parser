# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'easy_options_parser'
  s.version     = '1.0.0'
  s.date        = '2018-04-15'
  s.summary     = 'A wrapper around Ruby\'s OptionParser that makes it easier '\
                  'to define the command line options of your ruby scripts'
  s.description = 'Easy Option Parser - An easy to use wrapper wrapper '\
                  'around Ruby\'s OptionParser'
  s.authors     = ['Steve Vanspall']
  s.email       = 'steve@vanspall.id.au'
  s.files       = ['lib/easy_options_parser.rb']
  s.add_dependency 'activesupport'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'yard'
  s.license = 'MIT'
end
