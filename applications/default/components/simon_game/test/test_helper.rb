$:.unshift File.dirname(__FILE__) + '/../../../../../lib'
require 'adhearsion'
require 'test/unit'
require 'flexmock/test_unit'
AHN_ROOT = Adhearsion::PathString.new(File.dirname(__FILE__) + '/../../..')
Adhearsion::ComponentManager.load
Adhearsion::ComponentManager.start

class Test::Unit::TestCase
  Adhearsion::ComponentManager.components_with_call_context.each_pair do |component_class_name, component_configuration|
    const_set(component_class_name, component_configuration.component_class)
    const_get(component_class_name).send(:attr_accessor, :call_context)
  end
end