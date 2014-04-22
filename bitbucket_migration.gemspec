# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bitbucket_migration/version'

Gem::Specification.new do |spec|
  spec.name          = "bitbucket_migration"
  spec.version       = BitbucketMigration::VERSION
  spec.authors       = ["Denis Vazhenin"]
  spec.email         = ["denis.vazhenin@me.com"]
  spec.description   = %q{Migrates existing git repositories to bitbucket.}
  spec.summary       = %q{Imports existing git repositories and exports them to bitbucket.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.0'

  spec.add_runtime_dependency 'git'
  spec.add_runtime_dependency 'rest-client'
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-expectations"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "ruby_gntp"
	spec.add_development_dependency "yard"
end
