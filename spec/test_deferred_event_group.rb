require File.join(File.dirname(__FILE__), *%w[.. test_helper])
require 'adhearsion/events/deferred_event_group'

context Adhearsion::Events::DeferredEventGroup do
  
  test 'should be a subclass of ThreadGroup' do
    assert DeferredEventGroup < ThreadGroup
  end
  
  test 'the constructor should enforce the name be a Symbol' do
    bad_names  = [123, "Foobar", Object.new]
    good_names = [:foo, :qaz, :'o hai wtf']
    
    bad_names.each do |bad_name|
      the_following_code {
        DeferredEventGroup.new(bad_name)
      }.should.raise ArgumentError
    end
    
    good_names.each do |good_name|
      the_following_code {
        DeferredEventGroup.new(good_name)
      }.should.not.raise
    end
  end
  
end
