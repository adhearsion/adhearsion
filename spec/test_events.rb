require File.join(File.dirname(__FILE__), 'test_helper')

context 'Definitions within an events.rb file' do
  
  include EventsSubsystemTestHelper
  
  before :each do
    Adhearsion::Events.reinitialize_framework_events_container!
  end
  
  test 'calling each() on a registrar defines a RegisteredEventCallback' do
    
    mock_file_access_with_text %{ events.framework.before_call.each { |event| event } }
    
    framework_events_container.register_namespace_path(:framework).register_callback_name(:before_call)
    callbacks = framework_events_container.callbacks_at_path :framework, :before_call
    load_events_file_from_mocked_filesystem
    
    callbacks.size.should.equal 1
    callbacks.first.should.be.kind_of Adhearsion::Events::RegisteredEventCallback
  end
  
  test 'the each() method does not exist on the object returned by events()' do
    the_following_code {
      load_code_from_mocked_filesystem %{ events.each {} }
    }.should.raise NoMethodError
  end
  
  test 'addressing a non-existent path raises an Exception' do
    [%{ events.monkeys! }, %{events.framework.icanhascheezburger}, %{events.framework}].each do |bad_code|
      the_following_code {
        load_code_from_mocked_filesystem bad_code
      }.should.raise Adhearsion::Events::UndefinedEventNamespace
    end
  end
  
end


# Hierarchy tests?

context 'Executing synchronous events defined within an events.rb file' do
  
  before :each do
    Adhearsion::Events.reinitialize_framework_events_container!
  end
  
  test 'an exception in a callback should be passed to ahn_log.events.error' do
    flexmock(ahn_log.events).should_receive(:error).once.with(/lolrus/)
    Adhearsion::Events.register_namespace_path(:ceiling_cat).register_callback_name(:watches_you)
    Adhearsion::Events.framework_events_container.events.ceiling_cat.watches_you.each { |prophecy| raise prophecy }
    the_following_code {
      Adhearsion::Events.framework_events_container.events.ceiling_cat.watches_you << "I has a lolrus!"
    }.should.not.raise RuntimeError
  end
  
  test 'events should execute the callbacks in the order in which they were defined' do
    order_keeper = []
    Adhearsion::Events.register_namespace_path(:foo, :bar).register_callback_name(:before_explosion)
    Adhearsion::Events.framework_events_container.events.foo.bar.before_explosion.each { |event| order_keeper << 1 }
    Adhearsion::Events.framework_events_container.events.foo.bar.before_explosion.each { |event| order_keeper << 2 }
    
    [:one, :two, :three].each do |number|
      Adhearsion::Events.framework_events_container.events.foo.bar.before_explosion << number
    end
    order_keeper.should == [1,2] * 3
  end
end

context 'Executing asynchronous events defined within an events.rb file' do
  
end

context "Defining new namespaces and events within an EventsDefinitionContainer's object graph" do
  
  attr_reader :container
  before :each do
    @container = Adhearsion::Events::EventsDefinitionContainer.new
  end
  
  test 'initializes a RootNamespace' do
    container.root.should.be.kind_of Adhearsion::Events::RootEventNamespace
  end
  
  test 'allows the registration of new namespaces' do
    container.register_namespace_path(:framework).register_callback_name(:after_call)
    container.callbacks_at_path(:framework, :after_call).empty?.should == true
  end
  
  test 'the callback is executed with the proper message' do
    container.register_namespace_path(:reporters).register_callback_name(:report)
    message_from_block = :has_not_executed_yet
    container.events.reporters.report(:foobar).each { |event| message_from_block = event }
    container.events.reporters.report << :got_here
    message_from_block.should.equal :got_here
  end
  
end

context 'NamespaceDefinitionCapturer' do
  
  attr_reader :namespace
  before :each do
    @namespace = flexmock 'a mock AbstractNamespace'
  end
  
  test 'captures any method and returns a NamespaceDefinitionCapturer' do
    nested_namespace = Adhearsion::Events::RegisteredEventNamespace.new(namespace)
    namespace.should_receive(:[]).once.with(:foobarz).and_return nested_namespace
    Adhearsion::Events::NamespaceDefinitionCapturer.new(namespace).foobarz.should.
      be.kind_of(Adhearsion::Events::NamespaceDefinitionCapturer)
  end
  
end

BEGIN {
  module EventsSubsystemTestHelper
    def mock_file_access_with_text(text)
      flexmock(File).should_receive(:read).once.and_return text
    end
    
    def framework_events_container
      Adhearsion::Events.framework_events_container
    end
    
    def load_code_from_mocked_filesystem(code)
      mock_file_access_with_text code
      load_events_file_from_mocked_filesystem
    end
    
    def load_events_file_from_mocked_filesystem
      Adhearsion::Events.load_definitions_from_file "events.rb"
    end
    
  end
}
