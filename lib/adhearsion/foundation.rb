# encoding: utf-8

require 'English'
require 'tmpdir'
require 'tempfile'

Dir.glob File.join(File.dirname(__FILE__), 'foundation', "*rb") do |file|
  require file
end
