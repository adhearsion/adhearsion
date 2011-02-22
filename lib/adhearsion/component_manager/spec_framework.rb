require 'adhearsion/component_manager/component_tester'
begin
  require 'rspec'
rescue LoadError
  abort "You do not have the 'rspec' gem installed! You must install it to continue.\n\nsudo gem install rspec\n\n"
end

module ComponentConfigurationSpecHelper
  def mock_component_config_with(new_config)
    Object.send(:remove_const, :COMPONENTS) rescue nil
    Object.send(:const_set, :COMPONENTS, OpenStruct.new(new_config))
  end
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.include ComponentConfigurationSpecHelper
end
