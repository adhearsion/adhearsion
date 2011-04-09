# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "adhearsion/version"

Gem::Specification.new do |s|
  s.name        = "adhearsion"
  s.version     = Adhearsion::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jay Phillips", "Jason Goecke", "Ben Klang"]
  s.email       = "dev&Adhearsion.com"
  s.homepage    = "http://adhearsion.com"
  s.summary     = "Adhearsion, open-source telephony development framework"
  s.description = "Adhearsion is an open-source telephony development framework"
  s.date        = Date.today.to_s

  s.rubyforge_project         = "adhearsion"
  s.rubygems_version          = "1.2.0"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.has_rdoc      = true

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      # Runtime dependencies
      s.add_runtime_dependency("bundler", [">= 1.0.10"])
      s.add_runtime_dependency("log4r", [">= 1.0.5"])
      s.add_runtime_dependency("activesupport", [">= 2.1.0"])
      # i18n is only strictly a dependency for ActiveSupport >= 3.0.0
      # Since it doesn't conflict with <3.0.0 we'll require it to be
      # on the safe side.
      s.add_runtime_dependency("i18n")
      s.add_runtime_dependency("rubigen", [">= 1.5.6"])

      # Development dependencies
      s.add_development_dependency('rubigen', [">= 1.5.6"])
      s.add_development_dependency('rspec', [">= 2.4.0"])
      s.add_development_dependency('flexmock')
      s.add_development_dependency('activerecord')
      s.add_development_dependency('rake')
    else
      s.add_dependency("bundler", [">= 1.0.10"])
      s.add_dependency("log4r", [">= 1.0.5"])
      s.add_dependency("activesupport", [">= 2.1.0"])
    end
  else
    s.add_dependency("bundler", [">= 1.0.10"])
    s.add_dependency("log4r", [">= 1.0.5"])
    s.add_dependency("activesupport", [">= 2.1.0"])
  end
end
