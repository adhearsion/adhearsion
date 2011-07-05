# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "adhearsion/version"

Gem::Specification.new do |s|
  s.name        = "adhearsion"
  s.version     = Adhearsion::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jay Phillips", "Jason Goecke", "Ben Klang", "Ben Langfeld"]
  s.email       = "dev&Adhearsion.com"
  s.homepage    = "http://adhearsion.com"
  s.summary     = "Adhearsion, open-source telephony development framework"
  s.description = "Adhearsion is an open-source telephony development framework"
  s.date        = Date.today.to_s

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Runtime dependencies
  s.add_runtime_dependency "bundler", [">= 1.0.10"]
  s.add_runtime_dependency "log4r", [">= 1.0.5"]
  s.add_runtime_dependency "activesupport", [">= 2.1.0"]
  # i18n is only strictly a dependency for ActiveSupport >= 3.0.0
  # Since it doesn't conflict with <3.0.0 we'll require it to be
  # on the safe side.
  s.add_runtime_dependency "i18n"
  s.add_runtime_dependency "json"
  s.add_runtime_dependency "rubigen", [">= 1.5.6"]
  s.add_runtime_dependency "rake"
  s.add_runtime_dependency "pry"

  # Development dependencies
  s.add_development_dependency 'rubigen', [">= 1.5.6"]
  s.add_development_dependency 'rspec', [">= 2.4.0"]
  s.add_development_dependency 'flexmock'
  s.add_development_dependency 'activerecord', [">= 2.1.0"]
  s.add_development_dependency 'rake'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'simplecov-rcov'
  s.add_development_dependency 'ci_reporter'
end
