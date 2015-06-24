# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        describe Input do
          include HasMockCallbackConnection

          let(:ami_client)      { double('AMI') }
          let(:translator)      { Translator::Asterisk.new ami_client, connection }
          let(:call)            { Translator::Asterisk::Call.new 'foo', translator, ami_client, connection }
          let(:original_command_options) { {} }

          let :original_command do
            Adhearsion::Rayo::Component::Input.new original_command_options
          end

          let :grammar do
            RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'pin' do
              rule id: 'digit' do
                one_of do
                  0.upto(9) { |d| item { d.to_s } }
                end
              end

              rule id: 'pin', scope: 'public' do
                item repeat: '2' do
                  ruleref uri: '#digit'
                end
              end
            end
          end

          subject { Input.new original_command, call }

          describe '#execute' do
            before { original_command.request! }

            it "calls send_progress on the call" do
              expect(call).to receive(:send_progress)
              subject.execute
            end

            before { allow(call).to receive :send_progress }

            let(:original_command_opts) { {} }

            let :original_command_options do
              { :mode => :dtmf, :grammar => { :value => grammar } }.merge(original_command_opts)
            end

            let (:ast13mode) { false }

            def ami_event_for_dtmf(digit, position)
              if ast13mode
                RubyAMI::Event.new 'DTMF' + (position == :start ? 'Begin' : '') + (position == :end ? 'End' : ''),
                  'Digit' => digit.to_s
              else
                RubyAMI::Event.new 'DTMF',
                  'Digit' => digit.to_s,
                  'Start' => position == :start ? 'Yes' : 'No',
                  'End'   => position == :end ? 'Yes' : 'No'
              end
            end

            def send_ami_events_for_dtmf(digit)
              call.process_ami_event ami_event_for_dtmf(digit, :start)
              call.process_ami_event ami_event_for_dtmf(digit, :end)
            end

            let(:reason) { original_command.complete_event(5).reason }

            describe "receiving DTMF events" do
              before do
                subject.execute
                expected_event
              end

              context "when a match is found" do
                before do
                  send_ami_events_for_dtmf 1
                  send_ami_events_for_dtmf 2
                end

                let :expected_nlsml do
                  RubySpeech::NLSML.draw do
                    interpretation confidence: 1 do
                      instance "dtmf-1 dtmf-2"
                      input "12", mode: :dtmf
                    end
                  end
                end

                let :expected_event do
                  Adhearsion::Rayo::Component::Input::Complete::Match.new nlsml: expected_nlsml
                end

                it "should send a success complete event with the relevant data" do
                  expect(reason).to eq(expected_event)
                end

                it "should not process further dtmf events" do
                  expect(subject).to receive(:process_dtmf).never
                  send_ami_events_for_dtmf 3
                end

                it "should not leave the recognizer running" do
                  expect(Celluloid::Actor.all.any? { |a| a.class == Translator::Asterisk::Component::DTMFRecognizer rescue false }).to eq(false)
                end

                context 'with an Asterisk 13 DTMFEnd event' do
                  let(:ast13mode) { true }
                  it "should send a success complete event with the relevant data" do
                    expect(reason).to eq(expected_event)
                  end
                end
              end

              context "when the match is invalid" do
                before do
                  send_ami_events_for_dtmf 1
                  send_ami_events_for_dtmf '#'
                end

                let :expected_event do
                  Adhearsion::Rayo::Component::Input::Complete::NoMatch.new
                end

                it "should send a nomatch complete event" do
                  expect(reason).to eq(expected_event)
                end

                context 'with an Asterisk 13 DTMFEnd event' do
                  let(:ast13mode) { true }
                  it "should send a nomatch complete event" do
                    expect(reason).to eq(expected_event)
                  end
                end
              end

              context "dtmf event received after recognizer has terminated" do
                before do
                  send_ami_events_for_dtmf 1
                  send_ami_events_for_dtmf '#'
                  subject.execute
                end

                let :expected_event do
                  Adhearsion::Rayo::Component::Input::Complete::NoMatch.new
                end

                it "should not crash the translator if the recognizer is dead" do
                  expect(Celluloid::Actor.all.map { |a| a.class }).to include(Translator::Asterisk::Component::DTMFRecognizer)
                  recognizer = Celluloid::Actor.all.find { |a| a.class == Translator::Asterisk::Component::DTMFRecognizer }
                  recognizer.terminate if recognizer
                  expect(Celluloid::Actor.all.map { |a| a.class }).not_to include(Translator::Asterisk::Component::DTMFRecognizer)
                  subject.process_dtmf 1 # trigger failure
                  expect(Celluloid::Actor.all.map { |a| a.class }).to include(translator.class)
                end
              end
            end

            describe 'grammar' do
              context 'unset' do
                let(:original_command_opts) { { :grammar => nil } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = Adhearsion::ProtocolError.new.setup 'option error', 'A grammar document is required.'
                  expect(original_command.response(0.1)).to eq(error)
                end
              end

              context 'with a builtin grammar' do
                let(:original_command_opts) { { grammar: { url: 'builtin:dtmf/boolean' } } }

                before do
                  subject.execute
                  expected_event
                  send_ami_events_for_dtmf 1
                end

                let :expected_nlsml do
                  RubySpeech::NLSML.draw do
                    interpretation confidence: 1 do
                      instance "true"
                      input "1", mode: :dtmf
                    end
                  end
                end

                let :expected_event do
                  Adhearsion::Rayo::Component::Input::Complete::Match.new nlsml: expected_nlsml
                end

                it "should use RubySpeech builtin grammar" do
                  expect(reason).to eq(expected_event)
                end
              end

              context 'with a parameterized builtin grammar' do
                let(:original_command_opts) { { grammar: { url: 'builtin:dtmf/boolean?n=3;y=4' } } }

                before do
                  subject.execute
                  expected_event
                  send_ami_events_for_dtmf 4
                end

                let :expected_nlsml do
                  RubySpeech::NLSML.draw do
                    interpretation confidence: 1 do
                      instance "true"
                      input "4", mode: :dtmf
                    end
                  end
                end

                let :expected_event do
                  Adhearsion::Rayo::Component::Input::Complete::Match.new nlsml: expected_nlsml
                end

                it "should use RubySpeech builtin grammar" do
                  expect(reason).to eq(expected_event)
                end
              end

              context 'with multiple grammars' do
                let(:original_command_opts) { { :grammars => [{:value => grammar}, {:value => grammar}] } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = Adhearsion::ProtocolError.new.setup 'option error', 'Only a single grammar is supported.'
                  expect(original_command.response(0.1)).to eq(error)
                end
              end
            end

            describe 'mode' do
              context 'unset' do
                let(:original_command_opts) { { :mode => nil } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = Adhearsion::ProtocolError.new.setup 'option error', 'A mode value other than DTMF is unsupported.'
                  expect(original_command.response(0.1)).to eq(error)
                end
              end

              context 'any' do
                let(:original_command_opts) { { :mode => :any } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = Adhearsion::ProtocolError.new.setup 'option error', 'A mode value other than DTMF is unsupported.'
                  expect(original_command.response(0.1)).to eq(error)
                end
              end

              context 'voice' do
                let(:original_command_opts) { { :mode => :voice } }
                it "should return an error and not execute any actions" do
                  subject.execute
                  error = Adhearsion::ProtocolError.new.setup 'option error', 'A mode value other than DTMF is unsupported.'
                  expect(original_command.response(0.1)).to eq(error)
                end
              end
            end

            describe 'terminator' do
              context 'set' do
                let(:original_command_opts) { { terminator: '#' } }

                before do
                  subject.execute
                  expected_event
                end

                let :grammar do
                  RubySpeech::GRXML.draw mode: 'dtmf', root: 'digits' do
                    rule id: 'digits' do
                      item repeat: '2-5' do
                        one_of do
                          0.upto(9) { |d| item { d.to_s } }
                        end
                      end
                    end
                  end
                end

                let :expected_nlsml do
                  RubySpeech::NLSML.draw do
                    interpretation confidence: 1 do
                      instance "dtmf-1 dtmf-2"
                      input "12", mode: :dtmf
                    end
                  end
                end

                let :expected_event do
                  Adhearsion::Rayo::Component::Input::Complete::Match.new nlsml: expected_nlsml
                end

                context "when encountered with a match" do
                  before do
                    send_ami_events_for_dtmf 1
                    send_ami_events_for_dtmf 2
                    send_ami_events_for_dtmf '#'
                  end

                  it "should send a match complete event with the relevant data" do
                    expect(reason).to eq(expected_event)
                  end

                  it "should not process further dtmf events" do
                    expect(subject).to receive(:process_dtmf).never
                    send_ami_events_for_dtmf 3
                  end
                end

                context "when encountered with a NoMatch" do
                  before do
                    send_ami_events_for_dtmf '#'
                  end

                  let :expected_event do
                    Adhearsion::Rayo::Component::Input::Complete::NoMatch.new
                  end

                  it "should send a nomatch complete event with the relevant data" do
                    expect(reason).to eq(expected_event)
                  end
                end

                context "when encountered with a PotentialMatch" do
                  before do
                    send_ami_events_for_dtmf 1
                    send_ami_events_for_dtmf '#'
                  end

                  let :expected_event do
                    Adhearsion::Rayo::Component::Input::Complete::NoMatch.new
                  end

                  it "should send a nomatch complete event with the relevant data" do
                    expect(reason).to eq(expected_event)
                  end
                end
              end
            end

            describe 'recognizer' do
              skip
            end

            describe 'initial-timeout' do
              context 'a positive number' do
                let(:original_command_opts) { { :initial_timeout => 1000 } }

                it "should not cause a NoInput if first input is received in time" do
                  subject.execute
                  send_ami_events_for_dtmf 1
                  sleep 1.5
                  send_ami_events_for_dtmf 2
                  expect(reason).to be_a Adhearsion::Rayo::Component::Input::Complete::Match
                end

                it "should cause a NoInput complete event to be sent after the timeout" do
                  subject.execute
                  sleep 1.5
                  send_ami_events_for_dtmf 1
                  send_ami_events_for_dtmf 2
                  expect(reason).to be_a Adhearsion::Rayo::Component::Input::Complete::NoInput
                end
              end

              context '-1' do
                let(:original_command_opts) { { :initial_timeout => -1 } }

                it "should not start a timer" do
                  expect(subject).to receive(:begin_initial_timer).never
                  subject.execute
                end
              end

              context 'unset' do
                let(:original_command_opts) { { :initial_timeout => nil } }

                it "should not start a timer" do
                  expect(subject).to receive(:begin_initial_timer).never
                  subject.execute
                end
              end

              context 'a negative number other than -1' do
                let(:original_command_opts) { { :initial_timeout => -1000 } }

                it "should return an error and not execute any actions" do
                  subject.execute
                  error = Adhearsion::ProtocolError.new.setup 'option error', 'An initial timeout value that is negative (and not -1) is invalid.'
                  expect(original_command.response(0.1)).to eq(error)
                end
              end
            end

            describe 'inter-digit-timeout' do
              context 'a positive number' do
                let(:original_command_opts) { { :inter_digit_timeout => 1000 } }

                it "should not prevent a Match if input is received in time" do
                  subject.execute
                  sleep 1.5
                  send_ami_events_for_dtmf 1
                  sleep 0.5
                  send_ami_events_for_dtmf 2
                  expect(reason).to be_a Adhearsion::Rayo::Component::Input::Complete::Match
                end

                it "should cause a NoMatch complete event to be sent after the timeout" do
                  subject.execute
                  sleep 1.5
                  send_ami_events_for_dtmf 1
                  sleep 1.5
                  send_ami_events_for_dtmf 2
                  expect(reason).to be_a Adhearsion::Rayo::Component::Input::Complete::NoMatch
                end

                context "with a trailing range repeat" do
                  let :grammar do
                    RubySpeech::GRXML.draw mode: 'dtmf', root: 'digits' do
                      rule id: 'digits', scope: 'public' do
                        item repeat: '2-5' do
                          '1'
                        end
                      end
                    end
                  end

                  context "when the buffer potentially matches the grammar" do
                    it "should cause a NoMatch complete event to be sent after the timeout" do
                      subject.execute
                      sleep 1.5
                      send_ami_events_for_dtmf 1
                      sleep 1.5
                      expect(reason).to be_a Adhearsion::Rayo::Component::Input::Complete::NoMatch
                    end
                  end

                  context "when the buffer matches the grammar" do
                    let :expected_nlsml do
                      RubySpeech::NLSML.draw do
                        interpretation confidence: 1 do
                          instance "dtmf-1 dtmf-1"
                          input '11', mode: :dtmf
                        end
                      end
                    end

                    it "should fire a match on timeout" do
                      subject.execute
                      sleep 1.5
                      send_ami_events_for_dtmf 1
                      sleep 0.5
                      send_ami_events_for_dtmf 1
                      sleep 1.5
                      expect(reason).to be_a Adhearsion::Rayo::Component::Input::Complete::Match
                      expect(reason.nlsml).to eq(expected_nlsml)
                    end

                    context "on the first keypress" do
                      let :grammar do
                        RubySpeech::GRXML.draw mode: 'dtmf', root: 'digits' do
                          rule id: 'digits', scope: 'public' do
                            item repeat: '1-5' do
                              '1'
                            end
                          end
                        end
                      end

                      it "should fire a match on timeout" do
                        subject.execute
                        sleep 1.5
                        send_ami_events_for_dtmf 1
                        sleep 0.5
                        send_ami_events_for_dtmf 1
                        sleep 1.5
                        expect(reason).to be_a Adhearsion::Rayo::Component::Input::Complete::Match
                        expect(reason.nlsml).to eq(expected_nlsml)
                      end
                    end
                  end
                end
              end

              context '-1' do
                let(:original_command_opts) { { :inter_digit_timeout => -1 } }

                it "should not start a timer" do
                  expect(subject).to receive(:begin_inter_digit_timer).never
                  subject.execute
                end
              end

              context 'unset' do
                let(:original_command_opts) { { :inter_digit_timeout => nil } }

                it "should not start a timer" do
                  expect(subject).to receive(:begin_inter_digit_timer).never
                  subject.execute
                end
              end

              context 'a negative number other than -1' do
                let(:original_command_opts) { { :inter_digit_timeout => -1000 } }

                it "should return an error and not execute any actions" do
                  subject.execute
                  error = Adhearsion::ProtocolError.new.setup 'option error', 'An inter-digit timeout value that is negative (and not -1) is invalid.'
                  expect(original_command.response(0.1)).to eq(error)
                end
              end
            end

            describe 'sensitivity' do
              skip
            end

            describe 'min-confidence' do
              skip
            end

            describe 'max-silence' do
              skip
            end
          end

          describe "#execute_command" do
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
              let(:reason) { original_command.complete_event(5).reason }

              before do
                command.request!
                original_command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                subject.execute_command command
                expect(command.response(0.1)).to eq(true)
                expect(reason).to be_a Adhearsion::Event::Complete::Stop
              end
            end
          end

        end
      end
    end
  end
end
