# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'msmg-hiera-templater'
  s.version = '0.0.1'
  s.authors = ['Andrew Smith']
  s.email = ['andrew.smith at moneysupermarket.com']
  s.required_ruby_version = '>=2.5'
  s.summary = 'Render ERB templates from heira without requiring puppet'
  s.description = 'MSM pubicly available Ruby'
  s.homepage = 'https://github.com/MSMFG/msmg-hiera-templater'
  s.license = 'Apache-2.0'
  s.files = `git ls-files -z`.split("\x0")
  s.add_runtime_dependency 'facter', ['~>4.2']
  s.add_runtime_dependency 'hiera', ['~>3.7']
  s.bindir = 'bin'
  s.executables << 'hiera-templater'
end
