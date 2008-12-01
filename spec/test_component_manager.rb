require File.dirname(__FILE__) + "/test_helper"

context "Ruby-level requirements of components" do
  
  include ComponentManagerTestHelper
  
  before :each do
    @component_manager = Adhearsion::Components::ComponentManager.new "/filesystem/access/should/be/mocked/out"
    Object.send :remove_const, :COMPONENTS if Object.const_defined?(:COMPONENTS)
    Object.send :const_set, :COMPONENTS, @component_manager.lazy_config_loader
  end
  
  test "constants should be available in the main namespace" do
    constant_name = "FOO_#{rand(10000000000)}"
    begin
      run_component_code <<-RUBY
        #{constant_name} = 123
      RUBY
      Module.const_get(constant_name).should.equal 123
    ensure
      Object.send(:remove_const, constant_name) rescue nil
    end
  end

  test "defined constants should be available within the methods_for block" do
    constant_name = "I_HAVE_#{rand(100000000000000)}_GUMMY_BEARS"
    code = <<-RUBY
      #{constant_name} = :its_true!
      methods_for :dialplan do
        throw #{constant_name}
      end
    RUBY
    the_following_code {
      run_component_code code
    }.should.throw :its_true!
  end
  
  test "initialization block should be called after the methods_for() blocks"
  
  test "defined methods should be recognized once defined" do
    run_component_code <<-RUBY
      methods_for :events do
        def foo
          :inside_foo!
        end
      end
    RUBY
    container_object = new_object_with_scope :events
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
  
  test "methods defined in separate blocks should be available if they share a scope" do
    run_component_code <<-RUBY
      methods_for :dialplan do
        def get_symbol
          :i_am_the_best_symbol_in_the_world
        end
      end
      methods_for :dialplan do
        def throw_best_symbol_in_the_world
          throw get_symbol
        end
      end
    RUBY
    obj = new_object_with_scope :dialplan
    the_following_code {
      obj.throw_best_symbol_in_the_world
    }.should.throw :i_am_the_best_symbol_in_the_world
  end
  
  test "privately defined methods should remain private" do
    return_value = "hear! hear! i'm private, indeed!"
    run_component_code <<-RUBY
      methods_for :generators do
        def i_am_public
          i_am_private.reverse
        end
        
        private

        def i_am_private
          "#{return_value}"
        end
      end
    RUBY
    object = new_object_with_scope(:generators)
    object.i_am_public.should.eql return_value.reverse
    the_following_code {
      object.i_am_private
    }.should.raise NoMethodError
  end
  
  test "load_components should load code with the proper filenames" do
    components_dir_path = "/path/to/somewhere/components"
    component_names = %w[fooo barr qazz]
    component_paths = component_names.map { |name| "#{components_dir_path}/#{name}" }
    
    flexmock(Dir).should_receive(:glob).once.with(components_dir_path + "/*").
        and_return(component_paths)
    flexstub(File).should_receive(:exists?).and_return true
    flexstub(File).should_receive(:directory?).and_return true
    
    manager = Adhearsion::Components::ComponentManager.new(components_dir_path)
    component_paths.each do |path|
      flexmock(manager).should_receive(:load_file).once.with "#{path}/#{File.basename(path)}.rb"
    end
    
    manager.load_components
  end
  
  test "load_file"
  
  test "the :global scope" do
    run_component_code <<-RUBY
      methods_for :global do
        def i_should_be_globally_available
          :found!
        end
      end
    RUBY
    i_should_be_globally_available.should.equal :found!
  end
  
  test "should have access to the COMPONENTS constant" do
    component_name = "am_not_for_kokoa"
    mock_component_config(component_name, <<-YAML)
host: localhost
port: 7007
array:
  - 1
  - 2
  - 3
    YAML
    run_component_code <<-RUBY
    methods_for(:dialplan) do
      def host
        COMPONENTS.#{component_name}["host"]
      end
      def port
        COMPONENTS.#{component_name}["port"]
      end
      def array
        COMPONENTS.#{component_name}["array"]
      end
    end
    RUBY
    obj = new_object_with_scope :dialplan
    obj.host.should.eql "localhost"
    obj.port.should.eql 7007
    obj.array.should.eql [1,2,3]
  end
  
  test "the delegate method should properly delegate arguments and a block to a specified object" do
    component_name = "writing_this_at_peets_coffee"
    mock_component_config(component_name, "{jay: phillips}")
    run_component_code <<-RUBY
    
    initialization do
      obj = Object.new
      def obj.foo
        :foo
      end
      def obj.bar
        :bar
      end
      COMPONENTS.#{component_name}[:foobar] = obj
    end
    
    methods_for :dialplan do
      delegate :#{component_name}, :to => :COMPONENTS
    end
    RUBY
    obj = new_object_with_scope :dialplan
    obj.send(component_name)[:foobar].foo.should.equal :foo
  end
  
  test "an initialized component should not have an 'initialize' private method since it's confusing"
  
  test "should find components in a project properly"
  test "should run the initialization block" do
    code = <<-RUBY
      initialization do
        throw :got_here!
      end
    RUBY
    the_following_code {
      run_component_code code
    }.should.throw :got_here!

  end
  
  test "should alias the initialization method to initialisation" do
    code = <<-RUBY
      initialisation do
        throw :BRITISH!
      end
    RUBY
    the_following_code {
      run_component_code code
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
    
    def mock_component_config(component_name, yaml)
      yaml = YAML.load(yaml) if yaml.kind_of?(String)
      flexmock(@component_manager.lazy_config_loader).should_receive(component_name).and_return yaml
    end
    
    def run_component_code(code)
      @component_manager.load_code(code)
    end
    
    def new_object_with_scope(scope)
      @component_manager.extend_object_with(Object.new, scope)
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
