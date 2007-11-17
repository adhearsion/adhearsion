# -*- ruby -*-
ENV['RUBY_FLAGS'] = "-I#{%w(lib ext bin test).join(File::PATH_SEPARATOR)}"

require 'rubygems'
require 'hoe'
require 'lib/adhearsion/version'
require 'rcov/rcovtask'
  
Hoe.new('adhearsion', Adhearsion::VERSION::STRING) do |p|
  p.rubyforge_name = 'adhearsion'
  p.author = 'Jay Phillips'
  p.email = 'Jay -at- Codemecca.com'
  p.summary = 'Adhearsion, open-source telephony integrator.'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.test_globs = ['spec/**/test_*.rb']
  p.extra_deps = [['rubigen', '>=1.0.6']]
end

Rcov::RcovTask.new do |t|
  t.test_files = Dir['spec/**/test_*.rb']
  t.output_dir = 'coverage'
  t.verbose = true
  t.rcov_opts.concat %w[--sort coverage --sort-reverse -x gems -x /var]
end

task :ragel do
  `ragel -n -R lib/adhearsion/voip/asterisk/ami/machine.rl | rlgen-ruby -o lib/adhearsion/voip/asterisk/ami/machine.rb`
end
