# encoding: utf-8

require 'English'
require 'tmpdir'
require 'tempfile'

# Require all other files here.
Dir.glob File.join(File.dirname(__FILE__), "*rb") do |file|
  require file
end
