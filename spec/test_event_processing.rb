require File.join(File.dirname(__FILE__), *%w[.. test_helper])
require 'adhearsion/events/events_definition_container'

context 'Dispatching an event'

context 'Deferring a block to run asynchronously' do
  
  test 'A new Thread object is instantiated with the block given'
  
end

module EventProcessingTestHelper
  def sample_events_file
    File.read(File.join(File.dirname(__FILE__), 'sample.rb'))
  end
end