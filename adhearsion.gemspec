# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "adhearsion/version"

Gem::Specification.new do |s|
  s.name        = "adhearsion"
  s.version     = Adhearsion::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jay Phillips", "Jason Goecke", "Ben Klang", "Ben Langfeld"]
  s.email       = "dev@adhearsion.com"
  s.homepage    = "http://adhearsion.com"
  s.summary     = "Adhearsion, open-source telephony development framework"
  s.description = "Adhearsion is an open-source telephony development framework"

  s.license = 'MIT'

  s.required_ruby_version = '>= 2.2.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activesupport', [">= 3.0.0"]
  s.add_runtime_dependency 'adhearsion-loquacious', ["~> 1.9"]
  s.add_runtime_dependency 'blather', ["~> 2.0"]
  s.add_runtime_dependency 'celluloid', ["~> 0.16.0"]
  s.add_runtime_dependency 'countdownlatch'
  s.add_runtime_dependency 'deep_merge'
  s.add_runtime_dependency 'ffi', ["~> 1.0"]
  s.add_runtime_dependency 'future-resource', ["~> 1.0"]
  s.add_runtime_dependency 'has-guarded-handlers', ["~> 1.6", ">= 1.6.3"]
  s.add_runtime_dependency 'i18n'
  s.add_runtime_dependency 'logging', ["~> 2.0"]
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'pry'
  s.add_runtime_dependency 'rake'
  s.add_runtime_dependency 'reel', ["~> 0.6.0"]
  s.add_runtime_dependency 'http_parser.rb', ["~> 0.6.0"] # Dependency of Reel, verions > 0.6.0 broken under JRuby
  s.add_runtime_dependency 'reel-rack', ["~> 0.2.0"]
  s.add_runtime_dependency 'ruby_ami', ["~> 2.2"]
  s.add_runtime_dependency 'ruby_jid', ["~> 1.0"]
  s.add_runtime_dependency 'ruby_speech', ["~> 3.0"]
  s.add_runtime_dependency 'state_machine', ["~> 1.0"]
  s.add_runtime_dependency 'thor'
  s.add_runtime_dependency 'virtus', ["~> 1.0"]

  s.add_development_dependency 'aruba'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'guard-cucumber'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rspec', ["~> 3.8"]
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'simplecov-lcov'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'guard-yard'
  s.add_development_dependency 'timecop'
end
