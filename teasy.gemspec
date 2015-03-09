# coding: utf-8
require_relative 'lib/teasy/version'

Gem::Specification.new do |spec|
  spec.name          = 'teasy'
  spec.version       = Teasy::VERSION
  spec.authors       = ['Kai Kuchenbecker']
  spec.email         = ['Kai.Kuchenbecker@invision.de']
  spec.summary       = %q{TODO: Write a short summary. Required.}
  spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'tzinfo', '~> 1.2'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'rubocop'
end
