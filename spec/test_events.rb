require File.join(File.dirname(__FILE__), 'test_helper')

context 'an events.rb file' do
  
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
    callbacks.first.should.be.kind_of Adhearsion::Events::EventCallbackRegistrar::RegisteredEventCallback
  end
  
  test 'the each() method does not exist on the object returned by events()' do
    the_following_code {
      load_code_from_mocked_filesystem %{ events.each {} }
    }.should.raise NoMethodError
  end
  
  test 'addressing a non-existent path raises an Exception' do
    [%{ events.monkeys! }, %{events.framework.icanhascheezburger}, %{events.framework}]
    
  end
  
end

context 'An EventsDefinitionContainer' do
  
  attr_reader :container
  before :each do
    @container = Adhearsion::Events::EventsDefinitionContainer.new
  end
  
  test 'initializes a RootNamespace' do
    container.root.should.be.kind_of Adhearsion::Events::RootEventNamespace
  end
  
  test 'allows the registration of new namespaces' do
    container.register_namespace_path(:framework).register_callback_name(:after_call)
    container.send(:callbacks_at_path, :framework, :after_call).empty?.should == true
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

# context 'Dispatching an event' do
#   
#   test "should enqueue the message"
#   
#   test "should pass the message into the event handler's block" do
#     real_message = Object.new
#     event_block = lambda do |block_message|
#       block_message.should.equal real_message
#       throw :handled_message
#     end
#     the_following_code do
#       Adhearsion::Events.handler_for(:framework, :before_call).enqueue_event(real_message)
#     end.should.throw(:handled_message)
#   end
#   
# end
# 
# context 'Defining new events handlers' do
#   
#   before :each do
#     Adhearsion::Events.clear_handlers!
#   end
#   
#   test 'should not allow defining handler blocks for non-leaf objects'
#   
#   test 'should return an EventHook object'
#   
#   test 'should register and make accessible new event handlers' do
#     Adhearsion::Events.register :dbus
#     Adhearsion::Events.all_handlers.size.should == 1
#   end
#   
#   test 'it works' do
#     # What are the kind of arguments that can be passed to an event? Can be any object (e.g. Hash, Call, Symbol)
#     # Is it necessary to specify them in the definiton? Would one ever need to specify both in different cases?
#     Adhearsion::Events.all_handlers.should.be.empty
#     Adhearsion::Events.register :freeswitch
#     Adhearsion::Events.all_handlers.size.should.equal 1
#   end
# end
# 
# 
# context 'Deferring a block to run asynchronously' do
#   
#   test 'A new Thread object is instantiated with the block given'
#   
# end
# 
# context 'Loading a file' do
#   
#   test "Creates a new instance in which the file's code is instance_eval()'d" do
#     filename = '/path/to/events.rb'
#     events_content = rand.to_s
#     flexmock(File).should_receive(:read).once.with(filename).and_return events_content
#     flexmock(Adhearsion::Events::EventsDefinitionContainer).new_instances.
#       should_receive(:instance_eval).once.with(events_content, String)
#     Adhearsion::Events::EventsDefinitionContainer.from(filename).should.
#       be.kind_of(Adhearsion::Events::EventsDefinitionContainer)
#   end
#   
# end
# 
# context 'A high-level test for loading sample events.rb implementations' do
#   
#   test 'unrecognized event handler names raise EventHandlerHierarchyNotFound'
#   test 'enqueued events invoke the proper block'
# end
# 
# context 'The default event sources' do
#   test 'framework'
#   test 'voip'
# end
# 
# context 'Unrecognized event handlers' do
#   test 'should very loudly print ahn_log.warn warnings before initialized'
# end
# 
# context 'DeferredEventGroup' do
#   
#   test 'should be a subclass of ThreadGroup' do
#     assert DeferredEventGroup < ThreadGroup
#   end
#   
#   test 'the constructor should enforce the name be a Symbol' do
#     bad_names  = [123, "Foobar", Object.new]
#     good_names = [:foo, :qaz, :'o hai wtf']
#     
#     bad_names.each do |bad_name|
#       the_following_code {
#         DeferredEventGroup.new(bad_name)
#       }.should.raise ArgumentError
#     end
#     
#     good_names.each do |good_name|
#       the_following_code {
#         DeferredEventGroup.new(good_name)
#       }.should.not.raise
#     end
#   end
#   
# end
# 
# module EventProcessingTestHelper
#   def sample_events_file
#     File.read(File.join(File.dirname(__FILE__), 'sample.rb'))
#   end
# end
# 
# # context 'Hierarchy tests' do
# #   test 'the private #ancestors method with three generations' do
# #     granny = Adhearsion::Events::HandlerProxy.new
# #     papa   = Adhearsion::Events::HandlerProxy.new(granny)
# #     sonny  = Adhearsion::Events::HandlerProxy.new(papa)
# #     
# #     sonny.send(:ancestors).should == [sonny, papa, granny]
# #   end
# # end