require_relative 'lib/sapis/version'

Gem::Specification.new do |spec|
  spec.name          = 'sapis'
  spec.version       = Sapis::VERSION
  spec.authors       = ['Saverio Miroddi']
  spec.email         = []

  spec.summary       = "Sav's APIs - A collection of Ruby utility helpers"
  spec.description   = 'A collection of utility helpers for Ruby including graphing, configuration management, concurrency, system operations, multimedia handling, and more.'
  spec.homepage      = 'https://github.com/saveriomiroddi/sapis'
  spec.license       = 'GPL-3.0'

  spec.required_ruby_version = '>= 2.6.0'

  spec.files = Dir[ 'lib/**/*.rb' ] + [ 'README.md' ]
  spec.require_paths = [ 'lib' ]

  # Runtime dependencies
  spec.add_dependency 'gruff', '~> 0.7'
  spec.add_dependency 'parseconfig', '~> 1.0'
  spec.add_dependency 'highline', '~> 2.0'
  spec.add_dependency 'sqlite3', '~> 1.4'

  # Development dependencies
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.metadata = {
    'source_code_uri' => 'https://github.com/saveriomiroddi/sapis',
    'bug_tracker_uri' => 'https://github.com/saveriomiroddi/sapis/issues'
  }
end
