source "http://rubygems.org"

gemspec

group :test do
  gem 'ahn-plugin-demo', :git => 'git://github.com/polysics/ahn-plugin-demo.git'
end

if RUBY_PLATFORM =~ /darwin/
  gem 'growl_notify'
  gem 'rb-fsevent'
end
