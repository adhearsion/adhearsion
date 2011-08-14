# -*- ruby -*-
ENV['RUBY_FLAGS'] = "-I#{%w(lib ext bin spec).join(File::PATH_SEPARATOR)}"

require 'rubygems'
require 'bundler/gem_tasks'
require 'bundler/setup'
require 'date'
require 'adhearsion/version'

task :default => :spec
task :gem => :build

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'ci/reporter/rake/rspec'
task :ci => ['ci:setup:rspec', :spec]

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb'] + %w[README.markdown TODO.markdown LICENSE]
  end
rescue LoadError
  STDERR.puts "\nCould not require() YARD! Install with 'gem install yard' to get the 'yardoc' task\n\n"
end

desc "Check Ragel version"
task :check_ragel_version do
  ragel_version_match = `ragel --version`.match /(\d)\.(\d)+/
  abort "Could not get Ragel version! Is it installed? You must have at least version 6.3" unless ragel_version_match
  big, small = ragel_version_match.captures.map &:to_i
  if big < 6 || (big == 6 && small < 3)
    abort "Please upgrade Ragel! You're on version #{ragel_version_match[0]} and must be on 6.3 or later"
  end
  if (big == 6 && small < 7)
    puts "WARNING: A change to Ruby since 1.9 affects the Ragel generated code."
    puts "WARNING: You MUST be using Ragel version 6.7 or have patched it using"
    puts "WARNING: the patch found at:"
    puts "WARNING: http://www.mail-archive.com/ragel-users@complang.org/msg00440.html"
  end
end

RAGEL_FILES = %w[lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb]

desc "Used to regenerate the AMI source code files. Note: requires Ragel 6.3 or later be installed on your system"
task :ragel => :check_ragel_version do
  RAGEL_FILES.each do |ragel_file|
    ruby_file = ragel_file.sub ".rl.rb", ".rb"
    puts `ragel -n -R #{ragel_file} -o #{ruby_file} 2>&1`
    raise "Failed generating code from Ragel file #{ragel_file}" if $?.to_i.nonzero?
  end
end

desc "Generates a GraphVis document showing the Ragel state machine"
task :visualize_ragel => :check_ragel_version do
  RAGEL_FILES.each do |ragel_file|
    base_name = File.basename ragel_file, ".rl.rb"
    puts "ragel -V #{ragel_file} -o #{base_name}.dot 2>&1"
    puts `ragel -V #{ragel_file} -o #{base_name}.dot 2>&1`
    raise "Failed generating code from Ragel file #{ragel_file}" if $?.to_i.nonzero?
  end
end

desc "Test that the .gemspec file executes"
task :debug_gem do
  require 'rubygems/specification'
  gemspec = File.read 'adhearsion.gemspec'
  spec = nil
  Thread.new { spec = eval("$SAFE = 3\n#{gemspec}") }.join
  puts "SUCCESS: Gemspec runs at the $SAFE level 3."
end
