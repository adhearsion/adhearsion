require 'spec_helper'

module Adhearsion
  class PunchblockPlugin
    describe Initializer do
      def initialize_punchblock_with_defaults
        initialize_punchblock_with_options :platform => :xmpp, :username => 'usera@127.0.0.1', :password => '1', :auto_reconnect => true 
      end

      def initialize_punchblock_with_options options = nil
        flexmock(Punchblock).should_receive(:connect)
        Adhearsion.config.plugins.punchblock = Adhearsion::BasicConfiguration.new options unless options.nil?
        Initializer.start
        Adhearsion.config.plugins.punchblock
      end

      before do
        Events.refresh!
      end

      let(:call_id)       { rand }
      let(:offer)         { ::Punchblock::Event::Offer.new.tap { |o| o.call_id = call_id } }
      let(:mock_call)     { flexmock('Call', :id => call_id).tap { |call| call.should_ignore_missing } }
      let(:mock_manager)  { flexmock 'a mock dialplan manager' }

      describe "starts the client with the default values" do
        subject {
          initialize_punchblock_with_defaults  
        }
        
        its(:username) { should == 'usera@127.0.0.1' }
        its(:password) { should == '1' }
        its(:auto_reconnect) { should == true }
      end

      it "starts the client with any overridden settings" do
        overrides = {:username => 'userb@127.0.0.1', :password => '123', :wire_logger => Adhearsion::Logging.get_logger(Punchblock), :transport_logger => Adhearsion::Logging.get_logger(Punchblock), :auto_reconnect => false}
        flexmock(::Punchblock::Connection::XMPP).should_receive(:new).once.with(overrides).and_return do
          flexmock 'Client', :event_handler= => true
        end
        initialize_punchblock_with_options overrides
      end

      describe 'using Asterisk' do
        let(:overrides) { {:username => 'test', :password => '123', :wire_logger => Adhearsion::Logging.get_logger(Punchblock), :transport_logger => Adhearsion::Logging.get_logger(Punchblock), :auto_reconnect => false} }

        it 'should start an Asterisk PB connection' do
          flexmock(::Punchblock::Connection::Asterisk).should_receive(:new).once.with(overrides).and_return do
            flexmock 'Client', :event_handler= => true
          end
          initialize_punchblock_with_options overrides.merge(:platform => :asterisk)
        end
      end

      it 'should place events from Punchblock into the event handler' do
        flexmock(Events.instance).should_receive(:trigger).once.with(:punchblock, offer)
        initialize_punchblock_with_defaults
        Initializer.client.handle_event offer
      end

      describe "dispatching an offer" do
        it 'should hand the call off to a new Manager' do
          initialize_punchblock_with_defaults
          flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return mock_call
          flexmock(DialPlan::Manager).should_receive(:handle).once.with(mock_call)
          Events.trigger_immediately :punchblock, offer
        end
      end

      describe "dispatching a call event" do
        let(:mock_event)  { flexmock 'Event', :call_id => call_id }
        let(:latch)       { CountDownLatch.new 1 }

        describe "with an active call" do
          before do
            initialize_punchblock_with_defaults
            Adhearsion.active_calls << mock_call
          end

          it "should log an error" do
            flexmock(Adhearsion::Logging.get_logger(Initializer)).should_receive(:info).once.with("Event received for call #{call_id}: #{mock_event.inspect}")
            Events.trigger_immediately :punchblock, mock_event
          end

          it "should place the event in the call's inbox" do
            mock_call.should_receive(:<<).once.with(mock_event)
            Initializer.dispatch_call_event mock_event, latch
            latch.wait(10).should be_true
          end
        end

        describe "with an inactive call" do
          let(:mock_event) { flexmock 'Event', :call_id => call_id }

          it "should log an error" do
            flexmock(Adhearsion::Logging.get_logger(Initializer)).should_receive(:error).once.with("Event received for inactive call #{call_id}: #{mock_event.inspect}")
            Initializer.dispatch_call_event mock_event
          end
        end
      end

      context "Punchblock configuration" do
        describe "with config specified" do
          subject do
            Adhearsion.config.plugins.punchblock = Adhearsion::BasicConfiguration.new :username => 'userb@127.0.0.1', :password => 'abc123', :auto_reconnect => false
          end

          its(:username) { should == 'userb@127.0.0.1' }
          its(:password) { should == 'abc123' }
          its(:auto_reconnect) {should == false }
        end

      end


    end
  end
end
