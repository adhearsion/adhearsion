require 'spec_helper'
require 'adhearsion/component_manager/component_tester'

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

describe "Adhearsion's component system" do

  include ComponentManagerTestHelper

  before :each do
    @component_manager = Adhearsion::Components::ComponentManager.new "/filesystem/access/should/be/mocked/out"
    Object.send :remove_const, :COMPONENTS if Object.const_defined?(:COMPONENTS)
    Object.send :const_set, :COMPONENTS, @component_manager.lazy_config_loader
  end

  it "constants should be available in the main namespace" do
    constant_name = "FOO_#{rand(10000000000)}"
    begin
      run_component_code <<-RUBY
        #{constant_name} = 123
      RUBY
      Module.const_get(constant_name).should be 123
    ensure
      Object.send(:remove_const, constant_name) rescue nil
    end
  end

  it "defined constants should be available within the methods_for block" do
    constant_name = "I_HAVE_#{rand(100000000000000)}_GUMMY_BEARS"
    code = <<-RUBY
      #{constant_name} = :its_true!
      methods_for :dialplan do
        throw #{constant_name}
      end
    RUBY
    the_following_code {
      run_component_code code
    }.should throw_symbol :its_true!
  end

  it "initialization block should be called after the methods_for() blocks"

  it "defined methods should be recognized once defined" do
    run_component_code <<-RUBY
      methods_for :events do
        def foo
          :inside_foo!
        end
      end
    RUBY
    container_object = new_object_with_scope :events
    container_object.foo.should be :inside_foo!
  end

  it "a method defined in one scope should not be available in another" do
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

  it "methods defined in separate blocks should be available if they share a scope" do
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
    }.should throw_symbol :i_am_the_best_symbol_in_the_world
  end

  it "privately defined methods should remain private" do
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
    object.i_am_public.should == return_value.reverse
    the_following_code {
      object.i_am_private
    }.should raise_error NoMethodError
  end

  it "load_components should load code with the proper filenames" do
    components_dir_path = "/path/to/somewhere/components"
    component_names = %w[fooo barr qazz]
    component_paths = component_names.map { |name| "#{components_dir_path}/#{name}" }

    flexmock(Dir).should_receive(:glob).once.with(components_dir_path + "/*").
        and_return(component_paths + ["disabled"])
    flexstub(File).should_receive(:exists?).and_return true
    flexstub(File).should_receive(:directory?).and_return true

    manager = Adhearsion::Components::ComponentManager.new(components_dir_path)
    component_paths.each do |path|
      flexmock(manager).should_receive(:load_file).once.with "#{path}/lib/#{File.basename(path)}.rb"
    end

    manager.load_components
  end

  it "the :global scope" do
    run_component_code <<-RUBY
      methods_for :global do
        def i_should_be_globally_available
          :found!
        end
      end
    RUBY
    @component_manager.globalize_global_scope!
    i_should_be_globally_available.should be :found!
  end

  it "methods defined in outside of any scope should not be globally available" do
    run_component_code <<-RUBY
      def i_should_not_be_globally_available
        :found!
      end
    RUBY
    the_following_code {
      i_should_not_be_globally_available
    }.should raise_error NameError
  end

  it "should have access to the COMPONENTS constant" do
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
    obj.host.should =="localhost"
    obj.port.should ==7007
    obj.array.should ==[1,2,3]
  end

  it "the delegate method should properly delegate arguments and a block to a specified object" do
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
    obj.send(component_name)[:foobar].foo.should be :foo
  end

  it "an initialized component should not have an 'initialize' private method since it's confusing"

  it "should find components in a project properly"
  it "should run the initialization block" do
    code = <<-RUBY
      initialization do
        throw :got_here!
      end
    RUBY
    the_following_code {
      run_component_code code
    }.should throw_symbol :got_here!

  end

  it "should alias the initialization method to initialisation" do
    code = <<-RUBY
      initialisation do
        throw :BRITISH!
      end
    RUBY
    the_following_code {
      run_component_code code
    }.should throw_symbol :BRITISH!
  end

  it "should properly expose any defined constants" do
    container = run_component_code <<-RUBY
      TEST_ONE   = 1
      TEST_TWO   = 2
      TEST_THREE = 3
    RUBY
    container.constants.sort.map{|s| s.to_sym}.should == [:TEST_ONE, :TEST_THREE, :TEST_TWO]
    container.constants.map do |constant|
      container.const_get(constant)
    end.sort.should ==[1,2,3]
  end

end

describe "ComponentTester" do
  it "should allow the scope-resolution operator to access a component's constants" do
    component_name = "my_awesomeness"
    flexmock(File).should_receive(:read).once.with(/#{component_name}\.rb$/).and_return "AWESOME = :YES!"
    tester = ComponentTester.new(component_name, "/path/shouldnt/matter")
    tester::AWESOME.should be :YES!
  end

  it "should return an executable helper method properly" do
    component_name = "one_two_three"
    flexmock(File).should_receive(:read).once.with(/#{component_name}\.rb$/).and_return "def hair() :long end"
    tester = ComponentTester.new(component_name, "/path/shouldnt/matter")
    tester.helper_method(:hair).call.should be :long
  end

  it "should load the configuration for the given helper properly" do
    component_name = "i_like_configurations"
    config = {:german => {1 => :eins, 2 => :zwei, 3 => :drei}}
    flexmock(File).should_receive(:read).once.with(/#{component_name}\.rb$/).and_return ""
    component_manager = flexmock "ComponentManager"
    component_manager.should_receive(:configuration_for_component_named).once.with(component_name).and_return config
    flexmock(Adhearsion::Components::ComponentManager).should_receive(:new).once.and_return component_manager
    ComponentTester.new(component_name, "/path/shouldnt/matter").config[:german][1].should be :eins
  end

  it "should execute the initialize block when calling ComponentTester#initialize!()" do
    component_name = "morrissey"
    flexmock(File).should_receive(:read).once.with(/#{component_name}\.rb$/).and_return "initialization { $YES_I_WAS_CALLED = TRUE }"
    ComponentTester.new(component_name, "/path/shouldnt/matter").initialize!
    $YES_I_WAS_CALLED.should == true
  end

end
