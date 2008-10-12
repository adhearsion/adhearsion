require File.join(File.dirname(__FILE__), "spec_helper")
require File.join(File.dirname(__FILE__), *%w[.. event_handler.rb])

context "Registration of events" do
  
  include EventHandlerTestHelper
  
  after:each do
    EventHandler.clear!
  end
  
  specify "registered_patterns() should contain all patterns when a subclass executes on() " do
    
    pattern_one = "one"
    subclass_and_register_pattern pattern_one
    
    pattern_two = "two"
    subclass_and_register_pattern pattern_two
    
    EventHandler.registered_patterns.size.should.equal 2
    EventHandler.registered_patterns.has_key?("one").should.equal true
    EventHandler.registered_patterns.has_key?("two").should.equal true
    
  end
  
  it "should raise an error if no block is given" do
    the_following_code {
      subclass_and_register_pattern_with_block("does_not_matter")
    }.should.raise
  end
  
  it "should clear all registered patterns with clear!()" do
    subclass_and_register_pattern "pattern_doesnt_matter"
    EventHandler.registered_patterns.size.should.equal 1
    EventHandler.clear!
    EventHandler.registered_patterns.should.be.empty
  end
 
  it "should have no registered patterns by default" do
    EventHandler.registered_patterns.should.be.empty
  end
  
end

context "Handling an incoming event" do
  
  include EventHandlerTestHelper
  
  after:each do
    EventHandler.clear!
  end
  
  it "should pass all events to the :all Symbol pattern" do
    times_executed = 0
    klass = subclass_and_register_pattern_with_block(:any) { times_executed += 1 }
    *events = {"Hash" => "Two", "Qaz" => "Qwerty", "Action" => "urhomeerly"},
              { "Qaz" => "Qwerty"}, {"Hash" => "One", "Foo" => "Bar"}, {"IHas" => "A Bucket"}
    events.each { |event| klass.handle_event event }
    times_executed.should.equal events.size
  end
  
  specify "The block should receive the event as a block argument" do
    klass = subclass_and_register_pattern_with_block "This" => "Matches" do |event|
      event.should == {"This" => "Matches"}
    end
  end
  
  it "should use a pre-defined pattern when given an arbitrary Symbol pattern" do
    this_should_throw :pattern_matched! do
      symbol_pattern = :conference_created
      subclass_and_register_pattern(symbol_pattern).handle_event(
        EventHandler.pattern_for_symbol(symbol_pattern)
      )
    end
  end
  
  it "should raise an error when unrecognized pre-defined pattern is used" do
    the_following_code {
      subclass_and_register_pattern :this_doesnt_and_will_never_exist
    }.should.raise RuntimeError
  end
  
  specify "a String pattern should match actions with the name specified in the String" do
    this_should_throw :pattern_matched! do
      subclass_and_register_pattern("ohai").handle_event "Action" => "ohai"
    end
    this_should_not_throw do
      subclass_and_register_pattern("ohai").handle_event "Action" => "random_name"
    end
  end
  
  specify "key/value pairs in a Hash should be a proper pattern for matching events with identical key/value pairs" do
    
    this_should_throw :pattern_matched! do
      
      klass = subclass_and_register_pattern "ActionID" => "12345", "Channel" => "SIP/foobar-0c8ff"
      
      klass.handle_event "ActionID" => "12345" , "Channel" => "SIP/foobar-0c8ff",
                         "Doesnt"   => "Matter", "Foo"     => "Bar"
    end
    
    this_should_not_throw do
      klass = subclass_and_register_pattern "Randomness" => "IsSufficient", "ABC" => "DEF"
      klass.handle_event "ABC" => "DEF"
    end
    
  end
  
end

context "EventHandlerTestHelper" do
  
  include EventHandlerTestHelper
  
  after:each do
    EventHandler.clear!
  end
  
  specify "#subclass_and_register_pattern should throw the symbol given as the second argument" do
    this_should_throw :must_be_thrown do
      event_name = "ping"
      subclass_and_register_pattern(event_name, :must_be_thrown).handle_event(event_with_name(event_name))
    end
  end
  
  it "should throw :pattern_matched! normally" do
    this_should_throw :pattern_matched! do
      event_name = "login"
      subclass_and_register_pattern(event_name).handle_event(event_with_name(event_name))
    end
  end
  
  specify "#subclass_and_register_pattern_with_block should run the block given" do
    this_should_throw :got_here do
      event_name = "sippeers"
      subclass_and_register_pattern_with_block(event_name) do
        throw :got_here
      end.handle_event(event_with_name(event_name))
    end
  end
  
end

BEGIN {
module EventHandlerTestHelper
  def subclass_and_register_pattern(pattern, thrown_symbol=:pattern_matched!, &block)
    subclass_and_register_pattern_with_block pattern do
      throw thrown_symbol if thrown_symbol
    end
  end
  
  def subclass_and_register_pattern_with_block(pattern, &block)
    returning(Class.new(EventHandler)) do |klass|
      klass.class_eval do
        on(pattern, &block)
      end
    end
  end
  
  def this_should_throw(symbol, &block)
    block.should.throw symbol
  end
  
  def this_should_not_throw(&block)
    block.should.not.throw
  end
  
  def event_with_name(name)
    { "Action" => name }
  end
end
}