require 'adhearsion/component_manager/component_tester'
begin
  require 'spec'
rescue LoadError
  abort 'You do not have the "rspec" gem installed! You must install it to continue.\n\nsudo gem install rspec\n\n'
end

begin
  require 'rr'
rescue LoadError
  abort 'You do not have the "rr" gem installed! You must install it to continue.\n\nsudo gem install rr\n\n'  
end

Spec::Runner.configure do |config|
  config.mock_with :rr
end
