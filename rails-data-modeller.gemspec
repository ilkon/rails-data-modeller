# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'data_modeller/version'

Gem::Specification.new do |spec|
  spec.name          = 'rails-data-modeller'
  spec.version       = ::DataModeller::VERSION
  spec.authors       = ['Ilya Konyukhov']
  spec.email         = ['ilya@konyukhov.com']
  spec.summary       = 'A gem for generating a Rails application'
  spec.description   = 'The gem provides rake tasks which is used to generate parts of a Rails applications: models, migrations'
  spec.homepage      = 'https://github.com/ilkon/rails-data-modeller'
  spec.license       = 'No License'

  spec.files         = Dir['**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7.0'

  spec.add_runtime_dependency 'activesupport'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.metadata = {
    'rubygems_mfa_required' => 'true'
  }
end
