require 'spec_helper'

module Adhearsion
  class PunchblockPlugin
    describe Initializer do

      def initialize_punchblock options = nil

        flexmock(Initializer).should_receive(:connect)
        
        unless options.nil?
          Adhearsion.config.punchblock do |config|
            config.platform = options[:platform] if options.include? :platform
            config.username = options[:username] if options.include? :username
            config.password = options[:password] if options.include? :password
            config.auto_reconnect   = options[:auto_reconnect] if options.include? :auto_reconnect
            config.wire_logger      = options[:wire_logger] if options.include? :wire_logger
            config.transport_logger = options[:transport_logger] if options.include? :transport_logger
          end
        else
          Adhearsion.config.punchblock do |config|
            config.platform         = :xmpp
            config.username         = "usera@127.0.0.1"
            config.password         = "1"
            config.auto_reconnect   = true
            config.wire_logger      = nil
            config.transport_logger = nil
          end
        end

        Initializer.start
        Adhearsion.config[:punchblock]
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
          initialize_punchblock
        }
        
        it "should set properly the username value" do
          subject.username.should == 'usera@127.0.0.1'
        end

        it "should set properly the password value" do
          subject.password.should == '1'
        end

        it "should set properly the auto_reconnect value" do
          subject.auto_reconnect.should == true
        end
      end

      it "starts the client with any overridden settings" do
        overrides = {:username => 'userb@127.0.0.1', :password => '123', :auto_reconnect => false, :host=>nil, :port=>nil}

        flexmock(::Punchblock::Connection::XMPP).should_receive(:new).once.with(overrides).and_return do
          flexmock 'Client', :event_handler= => true
        end
        initialize_punchblock overrides
      end

      describe 'using Asterisk' do
        let(:overrides) { {:username => 'test', :password => '123', :auto_reconnect => false, :host=>nil, :port=>nil} }

        it 'should start an Asterisk PB connection' do
          flexmock(::Punchblock::Connection::Asterisk).should_receive(:new).once.with(overrides).and_return do
            flexmock 'Client', :event_handler= => true
          end
          initialize_punchblock overrides.merge(:platform => :asterisk)
        end
      end

      it 'should place events from Punchblock into the event handler' do
        flexmock(Events.instance).should_receive(:trigger).once.with(:punchblock, offer)
        initialize_punchblock
        Initializer.client.handle_event offer
      end

      describe "dispatching an offer" do
        it 'should reject a call with cause :declined if the Adhearsion::Process is in :booting' do
          initialize_punchblock
          flexmock(Adhearsion::Process).should_receive(:state_name).once.and_return :booting
          flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return mock_call
          mock_call.should_receive(:reject).once.with(:decline)
          Events.trigger_immediately :punchblock, offer
        end
        
        it 'should hand the call off to a new Manager when Adhearsion::Process is in :running' do
          initialize_punchblock
          flexmock(Adhearsion::Process).should_receive(:state_name).once.and_return :running
          flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return mock_call
          flexmock(DialPlan::Manager).should_receive(:handle).once.with(mock_call)
          Events.trigger_immediately :punchblock, offer
        end
        
        it 'should reject a call with cause :declined if the Adhearsion::Process is in :rejecting' do
          initialize_punchblock
          flexmock(Adhearsion::Process).should_receive(:state_name).once.and_return :rejecting
          flexmock(Adhearsion).should_receive(:receive_call_from).once.and_return mock_call
          mock_call.should_receive(:reject).once.with(:decline)
          Events.trigger_immediately :punchblock, offer
        end
        
        it 'should reject a call with cause :error if the Adhearsion::Process is not :running, :stopping or :rejecting' do
          initialize_punchblock
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
          initialize_punchblock
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
            initialize_punchblock
            Adhearsion.active_calls << mock_call
          end

          it "should log an error" do
            flexmock(Adhearsion::Logging.get_logger(Initializer)).should_receive(:debug).once.with("Event received for call #{call_id}: #{mock_event.inspect}")
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
          before do
            Adhearsion.config.punchblock do |config|
              config.username = 'userb@127.0.0.1'
              config.password = 'abc123'
              config.auto_reconnect = false
            end            
          end

          subject do
            Adhearsion.config[:punchblock]
          end

          it "should set properly the username value" do
            subject.username.should == 'userb@127.0.0.1'
          end

          it "should set properly the password value" do
            subject.password.should == 'abc123'
          end

          it "should set properly the auto_reconnect value" do
            subject.auto_reconnect.should == false
          end
        end

      end


    end
  end
end
