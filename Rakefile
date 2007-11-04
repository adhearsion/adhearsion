# -*- ruby -*-
ENV['RUBY_FLAGS'] = "-I#{%w(lib ext bin test).join(File::PATH_SEPARATOR)}"

require 'rubygems'
require 'hoe'
require 'lib/adhearsion/version'
  
Hoe.new('adhearsion', Adhearsion::VERSION::STRING) do |p|
  p.rubyforge_name = 'adhearsion'
  p.author = 'Jay Phillips'
  p.email = 'Jay -at- Codemecca.com'
  p.summary = 'Adhearsion, open-source telephony integrator.'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.test_globs = ['spec/**/test_*.rb']
end

task :ragel do
  `ragel -n -R lib/adhearsion/voip/asterisk/ami/machine.rl | rlgen-ruby -o lib/adhearsion/voip/asterisk/ami/machine.rb`
end
