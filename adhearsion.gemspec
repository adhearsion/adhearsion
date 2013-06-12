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

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activesupport', ["~> 3.0"]
  s.add_runtime_dependency 'adhearsion-loquacious', ["~> 1.9"]
  s.add_runtime_dependency 'bundler', ["~> 1.0"]
  s.add_runtime_dependency 'celluloid', ["~> 0.14"]
  s.add_runtime_dependency 'countdownlatch'
  s.add_runtime_dependency 'deep_merge'
  s.add_runtime_dependency 'ffi', ["~> 1.0"]
  s.add_runtime_dependency 'girl_friday'
  s.add_runtime_dependency 'has-guarded-handlers', ["~> 1.5"]
  s.add_runtime_dependency 'jruby-openssl' if RUBY_PLATFORM == 'java'
  s.add_runtime_dependency 'logging', ["~> 1.8"]
  s.add_runtime_dependency 'pry'
  s.add_runtime_dependency 'punchblock', ["~> 1.4"]
  s.add_runtime_dependency 'rake'
  s.add_runtime_dependency 'ruby_speech', ["~> 2.0"]
  s.add_runtime_dependency 'thor', "~> 0.18.0"

  s.add_development_dependency 'aruba', "~> 0.5"
  s.add_development_dependency 'ci_reporter'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'guard-cucumber'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rspec', ["~> 2.11"]
  s.add_development_dependency 'ruby_gntp'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'simplecov-rcov'
  s.add_development_dependency 'yard'
end
