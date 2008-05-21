require File.join(File.dirname(__FILE__), *%w[.. test_helper])
require 'adhearsion/events/events_definition_container'

context 'Loading a file' do
  test "Creates a new instance in which the file's code is instance_eval()'d" do
    filename = '/path/to/events.rb'
    events_content = rand.to_s
    flexmock(File).should_receive(:read).once.with(filename).and_return events_content
    flexmock(Adhearsion::Events::EventsDefinitionContainer).new_instances.
      should_receive(:instance_eval).once.with(events_content, String)
    Adhearsion::Events::EventsDefinitionContainer.from(filename).should.
      be.kind_of(Adhearsion::Events::EventsDefinitionContainer)
  end
end

context 'Defining new events handlers' do
  test 'should be Thread-safe'
  test 'should make the default event type-pattern Object' do
    Adhearsion::Events.register :dbus do |definer|
      definer.originate String, Hash, Symbol
    end
  end
  test 'it works' do
    # What are the kind of arguments that can be passed to an event? Can be any object (e.g. Hash, Call, Symbol)
    # Is it necessary to specify them in the definiton? Would one ever need to specify both in different cases?
    Adhearsion::Events.registered_events.should.be.empty
    Adhearsion::Events.register :freeswitch do |definer|
      definer.monkey Object
    end
    Adhearsion::Events.registered_events.size.should.equal 1
  end
end

context 'Unrecognized event handlers' do
  test 'should very loudly print ahn_log.warn warnings before initialized'
end
