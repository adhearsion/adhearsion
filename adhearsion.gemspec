Gem::Specification.new do |s|
  s.name = "adhearsion"
  s.version = "0.7.999"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jay Phillips"]
  s.date = "2008-07-26"
  s.description = "Adhearsion is an open-source VoIP development framework written in Ruby"
  s.email = "Jicksta (Gmail)"
  s.executables = ["ahn", "ahnctl", "jahn"]
  s.extra_rdoc_files = ["Manifest.txt", "README.txt"]
  s.files = Dir.glob("{ahn_generators,lib,spec,test,app_generators,bin}/**/*") +
            %w[adhearsion.gemspec CHANGELOG LICENSE Manifest.txt Rakefile README.txt app_generators/ahn/templates/.ahnrc]
            
  s.has_rdoc = true
  s.homepage = "http://adhearsion.com"
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{adhearsion}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Adhearsion, open-source telephony integrator.}
  s.test_files = Dir['spec/**/test_*.rb']

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<rubigen>, [">= 1.0.6"])
      s.add_runtime_dependency(%q<log4r>, [">= 1.0.5"])
    else
      s.add_dependency(%q<rubigen>, [">= 1.0.6"])
      s.add_dependency(%q<log4r>, [">= 1.0.5"])
    end
  else
    s.add_dependency(%q<rubigen>, [">= 1.0.6"])
    s.add_dependency(%q<log4r>, [">= 1.0.5"])
  end
end
