# -*- ruby -*-
ENV['RUBY_FLAGS'] = "-I#{%w(lib ext bin spec).join(File::PATH_SEPARATOR)}"

require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks
require 'date'
require 'adhearsion/version'

task :default => :spec
task :gem => :build

begin
  gem 'rspec', '>= 2.3.0'
  require 'rspec/core/rake_task'
rescue LoadError
  abort "You must install RSpec: sudo gem install rspec"
end

RSpec::Core::RakeTask.new do |t|
end

desc "Run all RSpecs for Theatre"
RSpec::Core::RakeTask.new(:theatre_specs) do |t|
  t.pattern = 'theatre-spec/**/*_spec.rb'
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.libs       << "spec"
    t.test_files  = Dir['spec/**/*_spec.rb']
    t.output_dir  = 'coverage'
    t.verbose     = true
    t.rcov_opts.concat %w[--sort coverage --sort-reverse -x gems -x /var]
  end
rescue LoadError
  STDERR.puts "Could not load rcov tasks -- rcov does not appear to be installed. Continuing anyway."
end

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
