# -*- ruby -*-
ENV['RUBY_FLAGS'] = "-I#{%w(lib ext bin test).join(File::PATH_SEPARATOR)}"

require 'rubygems'
require 'rake/gempackagetask'

begin
  require 'spec/rake/spectask'
rescue LoadError
  abort "You must install RSpec: sudo gem install rspec"
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files = ['lib/**/*.rb'] + %w[README.markdown TODO.markdown LICENSE]
  end
rescue LoadError
  STDERR.puts "\nCould not require() YARD! Install with 'gem install yard' to get the 'yardoc' task\n\n"
end

require 'lib/adhearsion/version'

AHN_TESTS     = ['spec/**/test_*.rb']
GEMSPEC       = eval File.read("adhearsion.gemspec")
RAGEL_FILES   = %w[lib/adhearsion/voip/asterisk/manager_interface/ami_lexer.rl.rb]
THEATRE_TESTS = 'theatre-spec/**/*_spec.rb'

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.test_files = Dir[*AHN_TESTS]
    t.output_dir = 'coverage'
    t.verbose = true
    t.rcov_opts.concat %w[--sort coverage --sort-reverse -x gems -x /var --no-validator-links]
  end
rescue LoadError
  STDERR.puts "Could not load rcov tasks -- rcov does not appear to be installed. Continuing anyway."
end

Rake::GemPackageTask.new(GEMSPEC).define

# YARD::Rake::YardocTask.new do |t|
#   t.files   = ['lib/**/*.rb']   # optional
#   # t.options = ['--any', '--extra', '--opts'] # optional
# end

desc "Run the unit tests for Adhearsion"
task :spec do
  Dir[*AHN_TESTS].each do |file|
    load file
  end
end

desc "Check Ragel version"
task :check_ragel_version do
  ragel_version_match = `ragel --version`.match(/(\d)\.(\d)+/)
  abort "Could not get Ragel version! Is it installed? You must have at least version 6.3" unless ragel_version_match
  big, small = ragel_version_match.captures.map { |n| n.to_i }
  if big < 6 || (big == 6 && small < 3)
    abort "Please upgrade Ragel! You're on version #{ragel_version_match[0]} and must be on 6.3 or later"
  end
end

desc "Used to regenerate the AMI source code files. Note: requires Ragel 6.3 or later be installed on your system"
task :ragel => :check_ragel_version do
  RAGEL_FILES.each do |ragel_file|
    ruby_file = ragel_file.sub(".rl.rb", ".rb")
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

desc "Run all RSpecs for Theatre"
Spec::Rake::SpecTask.new("theatre_specs") do |t|
  t.spec_files = FileList[THEATRE_TESTS]
end

desc "Compares Adhearsion's files with those listed in adhearsion.gemspec"
task :check_gemspec_files do
  
  files_from_gemspec    = ADHEARSION_FILES
  files_from_filesystem = Dir.glob(File.dirname(__FILE__) + "/**/*").map do |filename|
    filename[0...Dir.pwd.length] == Dir.pwd ? filename[(Dir.pwd.length+1)..-1] : filename
  end
  files_from_filesystem.reject! { |f| File.directory? f }
  
  puts
  puts 'Pipe this command to "grep -v \'spec/\' | grep -v test" to ignore test files'
  puts
  puts '##########################################'
  puts '## Files on filesystem not in the gemspec:'
  puts '##########################################'
  puts((files_from_filesystem - files_from_gemspec).map { |f| "  " + f })
  
  
  puts '##########################################'
  puts '## Files in gemspec not in the filesystem:'
  puts '##########################################'
  puts((files_from_gemspec - files_from_filesystem).map { |f| "  " + f })
end

desc "Test that the .gemspec file executes"
task :debug_gem do
  require 'rubygems/specification'
  gemspec = File.read('adhearsion.gemspec')
  spec = nil
  Thread.new { spec = eval("$SAFE = 3\n#{gemspec}") }.join
  puts "SUCCESS: Gemspec runs at the $SAFE level 3."
end

desc 'Install the package as a gem.'
task :install_gem => [:clobber_package, :package] do
  windows = /djgpp|(cyg|ms|bcc)win|mingw/ =~ RUBY_PLATFORM
  gem = Dir['pkg/*.gem'].first
  sh "#{'sudo ' unless windows}gem install --local #{gem}"
end
