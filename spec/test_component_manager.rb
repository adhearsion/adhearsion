require File.dirname(__FILE__) + "/test_helper"

context "Ruby-level requirements of components" do
  
  include ComponentManagerTestHelper
  
  test "constants should be available in the main namespace" do
    constant_name = "FOO_#{rand(10000000000)}"
    begin
      code = <<-RUBY
        #{constant_name} = 123
      RUBY
      run_component_code code
      Module.const_get(constant_name).should.equal 123
    ensure
      Object.send(:remove_const, constant_name) rescue nil
    end
  end
  test "defined constants should be available within the methods_for block"
  
  test "defined methods should be recognized once defined" do
    code = <<-RUBY
      methods_for :events do
        def foo
          :inside_foo!
        end
      end
    RUBY
    run_component_code code
    container_object = Object.new
    Adhearsion::Components.extend_object_with(container_object, :events)
    container_object.foo.should.equal :inside_foo!
  end
  
  test "a method defined in one scope should not be available in another" do
    code = <<-RUBY
      methods_for :events do
        def in_events
          in_dialplan
        end
      end
      methods_for :dialplan do
        def in_dialplan
          in_events
        end
      end
    RUBY
    
  end
  
  test "methods defined in separate blocks should be available if they share a scope"
  
  test "privately defined methods should remain private"
  test "should have access to the COMPONENTS constant"
  test "the delegate method should properly delegate arguments and a block to a specified object"
  
  test "an initialized component should not have an 'initialize' private method since it's confusing"
  
end

context "The component loader" do
  
  include ComponentManagerTestHelper
  
  test "should find components in a project properly"
  test "should run the initialization block" do
    code = <<-RUBY
      initialization do
        throw :got_here!
      end
    RUBY
    the_following_code {
      Adhearsion::Components.load_component_code(code)
    }.should.throw :got_here!

  end
  
  test "should alias the initialization method to initialisation" do
    code = <<-RUBY
      initialisation do
        throw :BRITISH!
      end
    RUBY
    the_following_code {
      Adhearsion::Components.load_component_code(code)
    }.should.throw :BRITISH!
  end
  
  test "should properly expose any defined constants" do
    container = run_component_code <<-RUBY
      TEST_ONE   = 1
      TEST_TWO   = 2
      TEST_THREE = 3
    RUBY
    container.constants.sort.should.eql ["TEST_ONE", "TEST_THREE", "TEST_TWO"]
    container.constants.map do |constant|
      container.const_get(constant)
    end.sort.should.eql [1,2,3]
  end
  
end


BEGIN {
  module ComponentManagerTestHelper
    def run_component_code(code)
      Adhearsion::Components.load_component_code(code)
    end
  end
}

# BEGIN {
#   module CallContextComponentTestHelpers
#     def new_componenet_class_named(component_name)
#       component_namespace = Adhearsion::Components::ComponentModule.new('passed in component does not matter here')
#       Adhearsion::Components::Component.prepare_component_class(component_namespace, component_name)
#       component_namespace.const_get(component_name)
#     end
#   end
# }
# 
# 
# context "Referencing a component class in a dial plan context" do
#   include CallContextComponentTestHelpers
#   
#   test "the component module constant should be available in the scope of a call context" do
#     sample_component_class = new_componenet_class_named 'SampleComponent2'
#     sample_component_class.add_call_context
# 
#     loader = load_dial_plan(<<-DIAL_PLAN)
#       some_context {
#         SampleComponent2
#       }
#     DIAL_PLAN
#     
#     flexmock(Adhearsion::DialPlan::Loader).should_receive(:load_dialplans).and_return(loader)
#     tested_call = Adhearsion::Call.new(nil, :context => :some_context)
#     Adhearsion::Configuration.configure
#     Adhearsion::AHN_CONFIG.ahnrc = {"paths" => {"dialplan" => "dialplan.rb"}}
#     flexmock(Adhearsion::AHN_CONFIG).should_receive(:automatically_answer_incoming_calls).once.and_return false
#     the_following_code {
#       handle(tested_call)
#     }.should.not.raise
#   end
#   
#   test "the call context is injected into any instances of the component class" do
#     sample_component_class = new_componenet_class_named('SampleComponent3')
#     sample_component_class.add_call_context :as => :call_context_variable_name
# 
#     loader = load_dial_plan(<<-DIAL_PLAN)
#       some_context {
#         new_sample_component3.call_context_variable_name
#       }
#     DIAL_PLAN
#     
#     flexmock(Adhearsion::DialPlan::Loader).should_receive(:load_dialplans).and_return(loader)
#     sample_call = Adhearsion::Call.new(nil, :context => :some_context)
#     Adhearsion::Configuration.configure
#     Adhearsion::AHN_CONFIG.ahnrc = {"paths" => {"dialplan" => "dialplan.rb"}}
#     flexmock(Adhearsion::AHN_CONFIG).should_receive(:automatically_answer_incoming_calls).once.and_return false
#     the_following_code {
#       handle(sample_call)
#     }.should.not.raise
#   end
#   
#   private
#     def load_dial_plan(dial_plan_as_string)
#       Adhearsion::DialPlan::Loader.load(dial_plan_as_string)
#     end
#     
#     def handle(call)
#       Adhearsion::DialPlan::Manager.handle(call)
#     end
# end
