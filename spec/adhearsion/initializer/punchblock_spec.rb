require 'spec_helper'

module Adhearsion
  class Initializer
    describe Punchblock do
      def initialize_punchblock_with_defaults
        initialize_punchblock_with_options Hash.new
      end

      def initialize_punchblock_with_options(options)
        flexmock(Punchblock).should_receive(:connect)
        Configuration.configure { |config| config.enable_punchblock options }
        Punchblock.start
      end

      before do
        Events.refresh!
      end

      let(:call_id)       { rand }
      let(:offer)         { ::Punchblock::Event::Offer.new.tap { |o| o.call_id = call_id } }
      let(:mock_call)     { flexmock('Call', :id => call_id).tap { |call| call.should_ignore_missing } }
      let(:mock_manager)  { flexmock 'a mock dialplan manager' }

      it "starts the client" do
        initialize_punchblock_with_defaults
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
        Punchblock.client.handle_event offer
      end

      describe "dispatching an offer" do
        it 'should reject a call with cause :declined if the Adhearsion::Process is in :booting' do
          initialize_punchblock_with_defaults
          flexmock(Adhearsion::Process).should_receive(:state_name).once.and_return :booting
          flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return mock_call
          mock_call.should_receive(:reject).once.with(:declined)
          Events.trigger_immediately :punchblock, offer
        end
        
        it 'should hand the call off to a new Manager when Adhearsion::Process is in :running' do
          initialize_punchblock_with_defaults
          flexmock(Adhearsion::Process).should_receive(:state_name).once.and_return :running
          flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return mock_call
          flexmock(DialPlan::Manager).should_receive(:handle).once.with(mock_call)
          Events.trigger_immediately :punchblock, offer
        end
        
        it 'should reject a call with cause :declined if the Adhearsion::Process is in :rejecting' do
          initialize_punchblock_with_defaults
          flexmock(Adhearsion::Process).should_receive(:state_name).once.and_return :rejecting
          flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return mock_call
          mock_call.should_receive(:reject).once.with(:declined)
          Events.trigger_immediately :punchblock, offer
        end
        
        it 'should reject a call with cause :error if the Adhearsion::Process is not :running, :stopping or :rejecting' do
          initialize_punchblock_with_defaults
          flexmock(Adhearsion::Process).should_receive(:state_name).once.and_return :not_a_real_valid_state
          flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return mock_call
          mock_call.should_receive(:reject).once.with(:error)
          Events.trigger_immediately :punchblock, offer
        end
      end

      describe "dispatching a component event" do
        let(:component)   { flexmock 'ComponentNode' }
        let(:mock_event)  { flexmock 'Event', :call_id => call_id, :source => component }

        before do
          initialize_punchblock_with_defaults
        end

        it "should place the event in the call's inbox" do
          component.should_receive(:trigger_event_handler).once.with mock_event
          Events.trigger_immediately :punchblock, mock_event
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
            flexmock(Adhearsion::Logging.get_logger(Punchblock)).should_receive(:info).once.with("Event received for call #{call_id}: #{mock_event.inspect}")
            Events.trigger_immediately :punchblock, mock_event
          end

          it "should place the event in the call's inbox" do
            mock_call.should_receive(:<<).once.with(mock_event)
            Punchblock.dispatch_call_event mock_event, latch
            latch.wait(10).should be_true
          end
        end

        describe "with an inactive call" do
          let(:mock_event) { flexmock 'Event', :call_id => call_id }

          it "should log an error" do
            flexmock(Adhearsion::Logging.get_logger(Punchblock)).should_receive(:error).once.with("Event received for inactive call #{call_id}: #{mock_event.inspect}")
            Punchblock.dispatch_call_event mock_event
          end
        end
      end
    end
  end
end
