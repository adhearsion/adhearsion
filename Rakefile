# -*- ruby -*-
ENV['RUBY_FLAGS'] = "-I#{%w(lib ext bin spec).join(File::PATH_SEPARATOR)}"

require 'rubygems'
require 'bundler/gem_tasks'
require 'bundler/setup'

task :default => [:spec, :features]
task :gem => :build

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = "-w -r./spec/capture_warnings"
end

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

task :encodeify do
  Dir['{bin,features,lib,spec}/**/*.rb'].each do |filename|
    File.open filename do |file|
      first_line = file.first
      if first_line == "# encoding: utf-8\n"
        puts "#{filename} is utf-8"
      else
        puts "Making #{filename} utf-8..."
        File.unlink filename
        File.open filename, "w" do |new_file|
          new_file.write "# encoding: utf-8\n\n"
          new_file.write first_line
          new_file.write file.read
        end
      end
    end
  end
end
