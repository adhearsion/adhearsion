require 'spec_helper'

module Adhearsion
  module Rayo
    module Commands
      describe Conference do
        include RayoCommandTestHelpers

        describe "#conference" do
          let(:conference_id) { 'abc123' }
          let(:options)       { { :mute => true } }

          it 'executes a Conference with the correct options' do
            expect_component_execution Punchblock::Component::Tropo::Conference.new(options.merge(:name => conference_id))
            mock_execution_environment.conference(conference_id, options).should be true
          end

          it "passes the block to component execution" do
            @conf = nil
            component = Punchblock::Component::Tropo::Conference.new(options.merge(:name => conference_id))
            expect_message_waiting_for_response component
            component.complete_event.resource = Punchblock::Event::Complete.new
            flexmock(Punchblock::Component::Tropo::Conference).should_receive(:new).and_return component
            mock_execution_environment.conference(conference_id, options) { |conf| @conf = conf }.should == component
            @conf.should == component
          end
        end
      end
    end
  end
end
