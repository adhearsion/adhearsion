# encoding: utf-8

require 'spec_helper'

module Adhearsion
  describe PunchblockPlugin do
    it "should make the client accessible from the Initializer" do
      PunchblockPlugin::Initializer.client = :foo
      expect(PunchblockPlugin.client).to be :foo
      PunchblockPlugin::Initializer.client = nil
    end

    describe '#execute_component' do
      let(:message)     { Punchblock::Command::Accept.new }
      let(:response)    { :foo }
      let(:mock_client) { double 'Client' }

      let(:execute_expectation) { expect(PunchblockPlugin.client).to receive(:execute_command).once }

      before do
        PunchblockPlugin::Initializer.client = mock_client
        allow(message).to receive_messages :execute! => true
        message.response = response
        execute_expectation
      end

      it "writes a command to the client" do
        execute_expectation.with(message, :async => true)
        PunchblockPlugin.execute_component message
      end

      it "blocks until a response is received" do
        slow_command = Punchblock::Command::Dial.new
        slow_command.request!
        starting_time = Time.now
        Thread.new do
          sleep 0.5
          slow_command.response = response
        end
        PunchblockPlugin.execute_component slow_command
        expect(Time.now - starting_time).to be >= 0.4
      end

      describe "with a successful response" do
        it "returns the executed command" do
          expect(PunchblockPlugin.execute_component(message)).to be message
        end
      end

      describe "with an error response" do
        let(:response) { Exception.new }

        it "raises the error" do
          expect { PunchblockPlugin.execute_component message }.to raise_error Exception
        end
      end
    end
  end
end
