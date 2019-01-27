# coding: utf-8
require File.expand_path("../lib/teasy/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'teasy'
  spec.version       = Teasy::VERSION
  spec.authors       = ['Kai Kuchenbecker']
  spec.email         = ['Kai.Kuchenbecker@invision.de']
  spec.summary       = %q{Teasy intends to make handling time zones easy.}
  spec.description   = %q{Teasy builds on tzinfo to get time zone data and
                          provides time classes to ease working with time zones.
                          It provides TimeWithZone which is similiar to Rails'
                          ActiveSupport::TimeWithZone but with less quirks. And
                          it provides FloatingTime which is time without a zone.
                        }
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '> 2.0'

  spec.add_runtime_dependency 'tzinfo', '~> 1.2'
  spec.add_runtime_dependency 'tzinfo-data', '~> 1.2018.9'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'rubocop'
end
