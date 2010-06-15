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

module ComponentConfigurationSpecHelper
  def mock_component_config_with(new_config)
    Object.send(:remove_const, :COMPONENTS) rescue nil
    Object.send(:const_set, :COMPONENTS, OpenStruct.new(new_config))
  end
end

Spec::Runner.configure do |config|
  config.mock_with :rr
  config.include ComponentConfigurationSpecHelper
end
