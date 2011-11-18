require 'spec_helper'

module Adhearsion
  module Punchblock
    module Commands
      describe Conference do
        include PunchblockCommandTestHelpers

        describe "#conference" do
          let(:conference_id) { 'abc123' }
          let(:options)       { { :mute => true } }

          it 'executes a Conference with the correct options' do
            expect_component_execution Punchblock::Component::Tropo::Conference.new(options.merge(:name => conference_id))
            mock_execution_environment.conference(conference_id, options)
          end

          it "passes the block to component execution" do
            @conf = nil
            component = Punchblock::Component::Tropo::Conference.new(options.merge(:name => conference_id))
            expect_message_waiting_for_response component
            component.execute!
            component.complete_event = Punchblock::Event::Complete.new
            flexmock(Punchblock::Component::Tropo::Conference).should_receive(:new).and_return component
            mock_execution_environment.conference(conference_id, options) { |conf| @conf = conf }.should == component
            @conf.should == component
          end

          describe "handling of active speaker notifications" do
            let(:response)          { flexmock 'Response' }
            let(:speaking_call_id)  { UUID.new.generate }

            let(:callback) { lambda { |var| @foo = var } }

            before do
              @foo = nil
              @bar = nil
            end

            context "when the speaking call is known to adhearsion" do
              it "calls the callback with a call object with the correct ID"
            end

            context "when the speaking call is not known to adhearsion" do
              before do
                @component = Punchblock::Component::Tropo::Conference.new :name => conference_id
                flexmock(Punchblock::Component::Tropo::Conference).should_receive(:new).and_return @component
                expect_message_waiting_for_response @component
                @conference_thread = Thread.new do
                  mock_execution_environment.conference conference_id, options
                end
                @component.execute!
              end

              context "with a speaking event" do
                let(:options) { {:on_speaking => callback } }

                let(:event) do
                  Punchblock::Component::Tropo::Conference::Speaking.new.tap do |e|
                    e.write_attr :'call-id', speaking_call_id
                  end
                end

                it "calls the on_speaking callback with the speaking call ID string" do
                  @component.add_event event
                end
              end

              context "with a finished speaking event" do
                let(:options) { {:on_finished_speaking => callback } }

                let(:event) do
                  Punchblock::Component::Tropo::Conference::FinishedSpeaking.new.tap do |e|
                    e.write_attr :'call-id', speaking_call_id
                  end
                end

                it "calls the on_finished_speaking callback with the speaking call ID string" do
                  @component.add_event event
                end
              end

              after do
                @component.add_event Punchblock::Event::Complete.new
                @conference_thread.join
                @foo.should == speaking_call_id
              end
            end
          end
        end
      end
    end
  end
end
