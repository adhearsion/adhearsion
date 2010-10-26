require 'English'
require 'tmpdir'
require 'tempfile'
begin
  # Try ActiveSupport >= 2.3.0
  require 'active_support/all'
rescue LoadError
  # Assume ActiveSupport < 2.3.0
  require 'active_support'
end

# Require all other files here.
Dir.glob File.join(File.dirname(__FILE__), "*rb") do |file|
  require file
end
