# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        describe Record do
          include HasMockCallbackConnection

          let(:channel)       { 'SIP/foo' }
          let(:ami_client)    { double('AMI Client').as_null_object }
          let(:translator)    { Translator::Asterisk.new ami_client, connection }
          let(:mock_call)     { Translator::Asterisk::Call.new channel, translator, ami_client, connection }

          let :original_command do
            Adhearsion::Rayo::Component::Record.new command_options
          end

          let :command_options do
            {}
          end

          subject { Record.new original_command, mock_call }

          describe '#execute' do
            let(:reason)    { original_command.complete_event(5).reason }
            let(:recording) { original_command.complete_event(5).recording }

            before { original_command.request! }

            it "returns an error if the call is not answered yet" do
              expect(mock_call).to receive(:answered?).and_return(false)
              subject.execute
              error = Adhearsion::ProtocolError.new.setup 'option error', 'Record cannot be used on a call that is not answered.'
              expect(original_command.response(0.1)).to eq(error)
            end

            before { allow(mock_call).to receive(:answered?).and_return(true) }

            it "sets command response to a reference to the component" do
              expect(ami_client).to receive(:send_action)
              subject.execute
              expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
              expect(original_command.component_id).to eq(subject.id)
            end

            it "starts a recording via AMI, using the component ID as the filename" do
              filename = "#{Record::RECORDING_BASE_PATH}/#{subject.id}"
              expect(ami_client).to receive(:send_action).once.with('Monitor', 'Channel' => channel, 'File' => filename, 'Format' => 'wav', 'Mix' => true)
              subject.execute
            end

            it "sends a max duration complete event when the recording ends" do
              full_filename = "file://#{Record::RECORDING_BASE_PATH}/#{subject.id}.wav"
              expect(ami_client).to receive(:send_action)
              subject.execute
              monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel
              mock_call.process_ami_event monitor_stop_event
              expect(reason).to be_a Adhearsion::Rayo::Component::Record::Complete::MaxDuration
              expect(recording.uri).to eq(full_filename)
              expect(original_command).to be_complete
            end

            it "can be called multiple times on the same call" do
              expect(ami_client).to receive(:send_action).twice
              subject.execute

              monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel

              mock_call.process_ami_event monitor_stop_event

              Record.new(original_command, mock_call).execute
              Adhearsion::Rayo::Component::Record.new(command_options).request!
              mock_call.process_ami_event monitor_stop_event
            end

            describe 'start_paused' do
              context "set to nil" do
                let(:command_options) { { :start_paused => nil } }
                it "should execute normally" do
                  expect(ami_client).to receive(:send_action).once
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end
              end

              context "set to false" do
                let(:command_options) { { :start_paused => false } }
                it "should execute normally" do
                  expect(ami_client).to receive(:send_action).once
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end
              end

              context "set to true" do
                let(:command_options) { { :start_paused => true } }
                it "should return an error and not execute any actions" do
                  expect(mock_call).to receive(:execute_agi_command).never
                  subject.execute
                  error = Adhearsion::ProtocolError.new.setup 'option error', 'A start-paused value of true is unsupported.'
                  expect(original_command.response(0.1)).to eq(error)
                end
              end
            end

            describe 'initial_timeout' do
              context "set to nil" do
                let(:command_options) { { :initial_timeout => nil } }
                it "should execute normally" do
                  expect(ami_client).to receive(:send_action).once
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end
              end

              context "set to -1" do
                let(:command_options) { { :initial_timeout => -1 } }
                it "should execute normally" do
                  expect(ami_client).to receive(:send_action).once
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end
              end

              context "set to a positive number" do
                let(:command_options) { { :initial_timeout => 10 } }
                it "should return an error and not execute any actions" do
                  expect(mock_call).to receive(:execute_agi_command).never
                  subject.execute
                  error = Adhearsion::ProtocolError.new.setup 'option error', 'An initial-timeout value is unsupported.'
                  expect(original_command.response(0.1)).to eq(error)
                end
              end
            end

            describe 'final_timeout' do
              context "set to nil" do
                let(:command_options) { { :final_timeout => nil } }
                it "should execute normally" do
                  expect(ami_client).to receive(:send_action).once
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end
              end

              context "set to -1" do
                let(:command_options) { { :final_timeout => -1 } }
                it "should execute normally" do
                  expect(ami_client).to receive(:send_action).once
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end
              end

              context "set to a positive number" do
                let(:command_options) { { :final_timeout => 10 } }
                it "should return an error and not execute any actions" do
                  expect(mock_call).to receive(:execute_agi_command).never
                  subject.execute
                  error = Adhearsion::ProtocolError.new.setup 'option error', 'A final-timeout value is unsupported.'
                  expect(original_command.response(0.1)).to eq(error)
                end
              end
            end

            describe 'format' do
              context "set to nil" do
                let(:command_options) { { :format => nil } }
                it "should execute as 'wav'" do
                  expect(ami_client).to receive(:send_action).once.with('Monitor', hash_including('Format' => 'wav'))
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end

                it "provides the correct filename in the recording" do
                  expect(ami_client).to receive(:send_action)
                  subject.execute
                  monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel
                  mock_call.process_ami_event monitor_stop_event
                  expect(recording.uri).to match(/.*\.wav$/)
                end
              end

              context "set to 'mp3'" do
                let(:command_options) { { :format => 'mp3' } }
                it "should execute as 'mp3'" do
                  expect(ami_client).to receive(:send_action).once.with('Monitor', hash_including('Format' => 'mp3'))
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end

                it "provides the correct filename in the recording" do
                  expect(ami_client).to receive(:send_action)
                  subject.execute
                  monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel
                  mock_call.process_ami_event monitor_stop_event
                  expect(recording.uri).to match(/.*\.mp3$/)
                end
              end

              context "set to 'wav49'" do
                let(:command_options) { { :format => 'wav49' } }
                it "should execute as 'wav49'" do
                  expect(ami_client).to receive(:send_action).once.with('Monitor', hash_including('Format' => 'wav49'))
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end

                it "provides the correct filename in the recording" do
                  expect(ami_client).to receive(:send_action)
                  subject.execute
                  monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel
                  mock_call.process_ami_event monitor_stop_event
                  expect(recording.uri).to match(/.*\.WAV$/)
                end
              end
            end

            describe 'start_beep' do
              context "set to nil" do
                let(:command_options) { { :start_beep => nil } }
                it "should execute normally" do
                  expect(mock_call).to receive(:execute_agi_command).never.with('STREAM FILE', 'beep', '""')
                  expect(ami_client).to receive(:send_action).once
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end
              end

              context "set to false" do
                let(:command_options) { { :start_beep => false } }
                it "should execute normally" do
                  expect(mock_call).to receive(:execute_agi_command).never.with('STREAM FILE', 'beep', '""')
                  expect(ami_client).to receive(:send_action).once
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end
              end

              context "set to true" do
                let(:command_options) { { :start_beep => true } }

                it "should play a beep before recording" do
                  expect(mock_call).to receive(:execute_agi_command).once.with('STREAM FILE', 'beep', '""').ordered.and_return code: 200
                  expect(ami_client).to receive(:send_action).once.ordered
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end

                context "when we get a RubyAMI Error" do
                  it "should send an error response" do
                    error = RubyAMI::Error.new.tap { |e| e.message = 'FooBar' }
                    expect(mock_call).to receive(:execute_agi_command).and_raise error
                    expect(ami_client).to receive(:send_action).never
                    subject.execute
                    error = Adhearsion::ProtocolError.new.setup :platform_error, "Terminated due to AMI error 'FooBar'"
                    expect(original_command.response(0.1)).to eq(error)
                  end
                end

                context "when the channel is no longer available" do
                  it "should send an error complete event" do
                    expect(mock_call).to receive(:execute_agi_command).and_raise ChannelGoneError
                    expect(ami_client).to receive(:send_action).never
                    subject.execute
                    error = Adhearsion::ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{mock_call.id}", mock_call.id)
                    expect(original_command.response(0.1)).to eq(error)
                  end
                end
              end
            end

            describe 'max_duration' do
              context "set to nil" do
                let(:command_options) { { :max_duration => nil } }
                it "should execute normally" do
                  expect(ami_client).to receive(:send_action).once
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end
              end

              context "set to -1" do
                let(:command_options) { { :max_duration => -1 } }
                it "should execute normally" do
                  expect(ami_client).to receive(:send_action).once
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end
              end

              context 'a negative number other than -1' do
                let(:command_options) { { :max_duration => -1000 } }

                it "should return an error and not execute any actions" do
                  subject.execute
                  error = Adhearsion::ProtocolError.new.setup 'option error', 'A max-duration value that is negative (and not -1) is invalid.'
                  expect(original_command.response(0.1)).to eq(error)
                end
              end

              context 'a positive number' do
                let(:reason) { original_command.complete_event(5).reason }
                let(:recording) { original_command.complete_event(5).recording }
                let(:command_options) { { :max_duration => 1000 } }

                it "executes a StopMonitor action" do
                  expect(ami_client).to receive :send_action
                  expect(ami_client).to receive(:send_action).once.with('StopMonitor', 'Channel' => channel)
                  subject.execute
                  sleep 1.2
                end

                it "should not kill the translator if the channel is down" do
                  expect(ami_client).to receive :send_action
                  error = RubyAMI::Error.new.tap { |e| e.message = 'No such channel' }
                  expect(ami_client).to receive(:send_action).once.with('StopMonitor', 'Channel' => channel).and_raise error
                  subject.execute
                  sleep 1.2
                  expect(translator).to be_alive
                end

                it "sends the correct complete event" do
                  full_filename = "file://#{Record::RECORDING_BASE_PATH}/#{subject.id}.wav"
                  subject.execute
                  sleep 1.2

                  monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel
                  mock_call.process_ami_event monitor_stop_event

                  expect(reason).to be_a Adhearsion::Rayo::Component::Record::Complete::MaxDuration
                  expect(recording.uri).to eq(full_filename)
                  expect(original_command).to be_complete
                end
              end
            end
          end

          describe "#execute_command" do
            let(:reason) { original_command.complete_event(5).reason }
            let(:recording) { original_command.complete_event(5).recording }

            context "with a command it does not understand" do
              let(:command) { Adhearsion::Rayo::Component::Output::Pause.new }

              before { command.request! }
              it "returns a Adhearsion::ProtocolError response" do
                subject.execute_command command
                expect(command.response(0.1)).to be_a Adhearsion::ProtocolError
              end
            end

            context "with a Stop command" do
              let(:command) { Adhearsion::Rayo::Component::Stop.new }

              before do
                expect(ami_client).to receive :send_action
                expect(mock_call).to receive(:answered?).and_return(true)
                command.request!
                original_command.request!
                subject.execute
              end

              let :send_stop_event do
                monitor_stop_event = RubyAMI::Event.new 'MonitorStop', 'Channel' => channel
                mock_call.process_ami_event monitor_stop_event
              end

              it "sets the command response to true" do
                expect(ami_client).to receive :send_action
                subject.execute_command command
                send_stop_event
                expect(command.response(0.1)).to eq(true)
              end

              it "executes a StopMonitor action" do
                expect(ami_client).to receive(:send_action).once.with('StopMonitor', 'Channel' => channel)
                subject.execute_command command
              end

              it "sends the correct complete event" do
                expect(ami_client).to receive(:send_action).and_return RubyAMI::Response.new

                full_filename = "file://#{Record::RECORDING_BASE_PATH}/#{subject.id}.wav"
                subject.execute_command command
                send_stop_event
                expect(reason).to be_a Adhearsion::Event::Complete::Stop
                expect(recording.uri).to eq(full_filename)
                expect(original_command).to be_complete
              end
            end

            context "with a Pause command" do
              let(:command) { Adhearsion::Rayo::Component::Record::Pause.new }

              before do
                command.request!
                original_command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                expect(ami_client).to receive(:send_action).and_return RubyAMI::Response.new
                subject.execute_command command
                expect(command.response(0.1)).to eq(true)
              end

              it "pauses the recording via AMI" do
                expect(ami_client).to receive(:send_action).once.with('PauseMonitor', 'Channel' => channel)
                subject.execute_command command
              end
            end

            context "with a Resume command" do
              let(:command) { Adhearsion::Rayo::Component::Record::Resume.new }

              before do
                command.request!
                original_command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                expect(ami_client).to receive(:send_action).and_return RubyAMI::Response.new
                subject.execute_command command
                expect(command.response(0.1)).to eq(true)
              end

              it "resumes the recording via AMI" do
                expect(ami_client).to receive(:send_action).once.with('ResumeMonitor', 'Channel' => channel)
                subject.execute_command command
              end
            end
          end

        end
      end
    end
  end
end
