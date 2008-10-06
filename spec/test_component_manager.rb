require File.dirname(__FILE__) + "/test_helper"

context "Adding call context to components" do
  include CallContextComponentTestHelpers
  
  attr_reader :sample_component
  
  setup do
    @sample_component = new_componenet_class_named(sample_component_name)
  end
  
  test "Component name is added to list of components that will have call contexts injected into them" do
    components_with_call_context.should.be.empty
    the_following_code {
      sample_component.add_call_context
    }.should.not.raise
    
    components_with_call_context.should.not.be.empty
    Adhearsion::ComponentManager.components_with_call_context[sample_component_name].component_class.should.equal sample_component
  end
  
  private
    def components_with_call_context
      Adhearsion::ComponentManager.components_with_call_context.keys
    end
    
    def sample_component_name
      'SampleComponent'
    end
end

context "Referencing a component class in a dial plan context" do
  include CallContextComponentTestHelpers
  
  test "the class constant should be available in the scope of a call context" do
    sample_component_class = new_componenet_class_named('SampleComponent2')
    sample_component_class.add_call_context

    loader = load_dial_plan(<<-DIAL_PLAN)
      some_context {
        SampleComponent2
      }
    DIAL_PLAN
    
    flexmock(Adhearsion::DialPlan::Loader).should_receive(:load_dialplan).and_return(loader)
    tested_call = Adhearsion::Call.new(nil, :context => :some_context)
    mock_config = flexmock 'a Configuration which communicates automatically_answer_incoming_calls properly',
                    :automatically_answer_incoming_calls => false
    flexmock(Adhearsion::Configuration).should_receive(:new).once.and_return mock_config
    Adhearsion::Configuration.configure
    
    the_following_code {
      handle(tested_call)
    }.should.not.raise
  end
  
  test "the call context is injected into any instances of the component class" do
    sample_component_class = new_componenet_class_named('SampleComponent3')
    sample_component_class.add_call_context :as => :call_context_variable_name

    loader = load_dial_plan(<<-DIAL_PLAN)
      some_context {
        new_sample_component3.call_context_variable_name
      }
    DIAL_PLAN
    
    flexmock(Adhearsion::DialPlan::Loader).should_receive(:load_dial_plan).and_return(loader)
    sample_call = Adhearsion::Call.new(nil, :context => :some_context)
    mock_config = flexmock 'a Configuration which communicates automatically_answer_incoming_calls properly',
                    :automatically_answer_incoming_calls => false
    flexmock(Adhearsion::Configuration).should_receive(:new).once.and_return mock_config
    Adhearsion::Configuration.configure
    
    the_following_code {
      handle(sample_call)
    }.should.not.raise
  end
  
  private
    def load_dial_plan(dial_plan_as_string)
      Adhearsion::DialPlan::Loader.load(dial_plan_as_string)
    end
    
    def handle(call)
      Adhearsion::DialPlan::Manager.handle(call)
    end
end

BEGIN {
  module CallContextComponentTestHelpers
    def new_componenet_class_named(component_name)
      component_namespace = Adhearsion::Components::ComponentModule.new('passed in component does not matter here')
      Adhearsion::Components::Component.prepare_component_class(component_namespace, component_name)
      component_namespace.const_get(component_name)
    end
  end
}