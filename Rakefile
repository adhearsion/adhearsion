# -*- ruby -*-
ENV['RUBY_FLAGS'] = "-I#{%w(lib ext bin spec).join(File::PATH_SEPARATOR)}"

require 'rubygems'
require 'bundler/gem_tasks'
require 'bundler/setup'

task :default => [:spec, :features]
task :gem => :build

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'ci/reporter/rake/rspec'
require 'ci/reporter/rake/cucumber'
task :ci => ['ci:setup:rspec', :spec, 'ci:setup:rspec', :features]

require 'cucumber'
require 'cucumber/rake/task'
require 'ci/reporter/rake/cucumber'
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = %w{--tags ~@jruby} unless defined?(JRUBY_VERSION)
end

Cucumber::Rake::Task.new(:wip) do |t|
  t.cucumber_opts = %w{-p wip -q}
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb'] + %w[README.markdown TODO.markdown LICENSE]
  end
rescue LoadError
  STDERR.puts "\nCould not require() YARD! Install with 'gem install yard' to get the 'yardoc' task\n\n"
end

task :stats do
  system 'doc/cloc-1.55.pl . --exclude-dir=.git,vendor,coverage,doc'
end
