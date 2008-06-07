# -*- ruby -*-
ENV['RUBY_FLAGS'] = "-I#{%w(lib ext bin test).join(File::PATH_SEPARATOR)}"

require 'rubygems'
require 'hoe'
require 'lib/adhearsion/version'

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.test_files = Dir['spec/**/test_*.rb']
    t.output_dir = 'coverage'
    t.verbose = true
    t.rcov_opts.concat %w[--sort coverage --sort-reverse -x gems -x /var --no-validator-links]
  end
rescue LoadError
  STDERR.puts "Could not load rcov tasks -- rcov does not appear to be installed."
end

TestGlob = ['spec/**/test_*.rb']

task :test do
  STDERR.puts "\nTry using \"rake spec\" for something less noisy.\n\n"
  # The other :test task is created by Hoe below.
end

# Need to migrate away from Hoe...
Hoe.new('adhearsion', Adhearsion::VERSION::STRING) do |p|
  p.rubyforge_name = 'adhearsion'
  p.author = 'Jay Phillips'
  p.email = 'Jay -at- Codemecca.com'
  p.summary = 'Adhearsion, open-source telephony integrator.'
  p.description = "Adhearsion is an open-source VoIP development framework written in Ruby"
  p.url = "http://adhearsion.com"
  p.changes = "" # Removed because History.txt is tedious.
  p.test_globs = TestGlob
  p.extra_deps = [['rubigen', '>=1.0.6'], ['log4r', '>=1.0.5']]
end

task :spec do
  Dir[*TestGlob].each do |file|
    load file
  end
end

task :ragel do
  `ragel -n -R lib/adhearsion/voip/asterisk/ami/machine.rl | rlgen-ruby -o lib/adhearsion/voip/asterisk/ami/machine.rb`
end