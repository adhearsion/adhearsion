# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module Translator
    class Asterisk
      module Component
        describe MRCPPrompt do
          include HasMockCallbackConnection

          let(:ami_client)    { double('AMI') }
          let(:translator)    { Translator::Asterisk.new ami_client, connection }
          let(:mock_call)     { Translator::Asterisk::Call.new 'foo', translator, ami_client, connection }

          let :ssml_doc do
            RubySpeech::SSML.draw do
              say_as(:interpret_as => :cardinal) { 'FOO' }
            end
          end

          let :voice_grammar do
            RubySpeech::GRXML.draw :mode => 'voice', :root => 'color' do
              rule id: 'color' do
                one_of do
                  item { 'red' }
                  item { 'blue' }
                  item { 'green' }
                end
              end
            end
          end

          let :dtmf_grammar do
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

          let(:grammar) { voice_grammar }

          let(:output_command_opts) { {} }

          let :output_command_options do
            { render_document: {value: ssml_doc} }.merge(output_command_opts)
          end

          let(:input_command_opts) { {} }

          let :input_command_options do
            { grammar: {value: grammar} }.merge(input_command_opts)
          end

          let(:command_options) { {} }

          let :output_command do
            Adhearsion::Rayo::Component::Output.new output_command_options
          end

          let :input_command do
            Adhearsion::Rayo::Component::Input.new input_command_options
          end

          let :original_command do
            Adhearsion::Rayo::Component::Prompt.new output_command, input_command, command_options
          end

          let(:recog_status)            { 'OK' }
          let(:recog_completion_cause)  { '000' }
          let(:recog_result)            { "%3C?xml%20version=%221.0%22?%3E%3Cresult%3E%0D%0A%3Cinterpretation%20grammar=%22session:grammar-0%22%20confidence=%220.43%22%3E%3Cinput%20mode=%22speech%22%3EHello%3C/input%3E%3Cinstance%3EHello%3C/instance%3E%3C/interpretation%3E%3C/result%3E" }

          subject { described_class.new original_command, mock_call }

          before do
            original_command.request!
            {
              'RECOG_STATUS' => recog_status,
              'RECOG_COMPLETION_CAUSE' => recog_completion_cause,
              'RECOG_RESULT' => recog_result
            }.each do |var, val|
              allow(mock_call).to receive(:channel_var).with(var).and_return val
            end
          end

          context 'with an invalid recognizer' do
            let(:input_command_opts) { { recognizer: 'foobar' } }

            it "should return an error and not execute any actions" do
              subject.execute
              error = Adhearsion::ProtocolError.new.setup 'option error', 'The recognizer foobar is unsupported.'
              expect(original_command.response(0.1)).to eq(error)
            end
          end

          [:asterisk].each do |recognizer|
            context "with a recognizer #{recognizer.inspect}" do
              let(:input_command_opts) { { recognizer: recognizer } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', "The recognizer #{recognizer} is unsupported."
                expect(original_command.response(0.1)).to eq(error)
              end
            end
          end

          def expect_mrcpsynth_with_options(options)
            expect_app_with_options 'MRCPSynth', options
          end

          def expect_synthandrecog_with_options(options)
            expect_app_with_options 'SynthAndRecog', options
          end

          def expect_app_with_options(app, options)
            expect(mock_call).to receive(:execute_agi_command).once { |*args|
              expect(args[0]).to eq("EXEC #{app}")
              expect(args[1]).to match options
              {code: 200, result: 1}
            }
          end

          describe 'Output#document' do
            context 'with multiple inline documents' do
              let(:output_command_options) { { render_documents: [{value: ssml_doc}, {value: ssml_doc}] } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'Only one document is allowed.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end

            context 'with multiple documents by URI' do
              let(:output_command_options) { { render_documents: [{url: 'http://example.com/doc1.ssml'}, {url: 'http://example.com/doc2.ssml'}] } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'Only one document is allowed.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end

            context 'unset' do
              let(:output_command_options) { {} }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'An SSML document is required.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end
          end

          describe 'Output#renderer' do
            [nil, :unimrcp].each do |renderer|
              context renderer.to_s do
                let(:output_command_opts) { { renderer: renderer } }

                it "should return a ref and execute SynthAndRecog" do
                  param = [ssml_doc.to_doc, grammar.to_doc].map { |o| "\"#{o.to_s.squish.gsub('"', '\"')}\"" }.push('uer=1&b=1').join(',')
                  expect(mock_call).to receive(:execute_agi_command).once.with('EXEC SynthAndRecog', param).and_return code: 200, result: 1
                  subject.execute
                  expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
                end

                context "when SynthAndRecog completes" do
                  shared_context "with a match" do
                    let :expected_nlsml do
                      RubySpeech::NLSML.draw do
                        interpretation grammar: 'session:grammar-0', confidence: 0.43 do
                          input 'Hello', mode: :speech
                          instance 'Hello'
                        end
                      end
                    end

                    it 'should send a match complete event' do
                      expected_complete_reason = Adhearsion::Rayo::Component::Input::Complete::Match.new nlsml: expected_nlsml

                      expect(mock_call).to receive(:execute_agi_command).and_return code: 200, result: 1
                      subject.execute
                      expect(original_command.complete_event(0.1).reason).to eq(expected_complete_reason)
                    end
                  end

                  context "with a  match cause" do
                    %w{000 008 012}.each do |code|
                      context "when the MRCP recognition response code is #{code}" do
                        let(:recog_completion_cause) { code }

                        it_behaves_like 'with a match'
                      end
                    end
                  end

                  context "with a nomatch cause" do
                    %w{001 003 013 014 015}.each do |code|
                      context "with value #{code}" do
                        let(:recog_completion_cause) { code }

                        it 'should send a nomatch complete event' do
                          expected_complete_reason = Adhearsion::Rayo::Component::Input::Complete::NoMatch.new
                          expect(mock_call).to receive(:execute_agi_command).and_return code: 200, result: 1
                          subject.execute
                          expect(original_command.complete_event(0.1).reason).to eq(expected_complete_reason)
                        end
                      end
                    end
                  end

                  context "with a noinput cause" do
                    %w{002 011}.each do |code|
                      context "with value #{code}" do
                        let(:recog_completion_cause) { code }

                        specify do
                          expected_complete_reason = Adhearsion::Rayo::Component::Input::Complete::NoInput.new
                          expect(mock_call).to receive(:execute_agi_command).and_return code: 200, result: 1
                          subject.execute
                          expect(original_command.complete_event(0.1).reason).to eq(expected_complete_reason)
                        end
                      end
                    end
                  end

                  shared_context 'should send an error complete event' do
                    specify do
                      expect(mock_call).to receive(:execute_agi_command).and_return code: 200, result: 1
                      subject.execute
                      complete_reason = original_command.complete_event(0.1).reason
                      expect(complete_reason).to be_a Adhearsion::Event::Complete::Error
                    end
                  end

                  context 'with an error cause' do
                    %w{004 005 006 007 009 010 016}.each do |code|
                      context "when the MRCP recognition response code is #{code}" do
                        let(:recog_completion_cause) { code }
                        it_behaves_like 'should send an error complete event'
                      end
                    end
                  end

                  context 'with an invalid cause' do
                    let(:recog_completion_cause) { '999' }
                    it_behaves_like 'should send an error complete event'
                  end

                  context "when the RECOG_STATUS variable is set to 'ERROR'" do
                    let(:recog_status) { 'ERROR' }
                    it_behaves_like 'should send an error complete event'
                  end
                end

                context "when we get a RubyAMI Error" do
                  it "should send an error complete event" do
                    error = RubyAMI::Error.new.tap { |e| e.message = 'FooBar' }
                    expect(mock_call).to receive(:execute_agi_command).and_raise error
                    subject.execute
                    complete_reason = original_command.complete_event(0.1).reason
                    expect(complete_reason).to be_a Adhearsion::Event::Complete::Error
                    expect(complete_reason.details).to eq("Terminated due to AMI error 'FooBar'")
                  end
                end

                context "when the channel is gone" do
                  it "should send an error complete event" do
                    error = ChannelGoneError.new 'FooBar'
                    expect(mock_call).to receive(:execute_agi_command).and_raise error
                    subject.execute
                    complete_reason = original_command.complete_event(0.1).reason
                    expect(complete_reason).to be_a Adhearsion::Event::Complete::Hangup
                  end
                end
              end
            end

            [:foobar, :swift, :asterisk].each do |renderer|
              context renderer.to_s do
                let(:output_command_opts) { { renderer: renderer } }

                it "should return an error and not execute any actions" do
                  subject.execute
                  error = Adhearsion::ProtocolError.new.setup 'option error', "The renderer #{renderer} is unsupported."
                  expect(original_command.response(0.1)).to eq(error)
                end
              end
            end
          end

          describe 'barge_in' do
            context 'unset' do
              let(:command_options) { { barge_in: nil } }

              it 'should pass the b=1 option to SynthAndRecog' do
                expect_synthandrecog_with_options(/b=1/)
                subject.execute
              end
            end

            context 'true' do
              let(:command_options) { { barge_in: true } }

              it 'should pass the b=1 option to SynthAndRecog' do
                expect_synthandrecog_with_options(/b=1/)
                subject.execute
              end
            end

            context 'false' do
              let(:command_options) { { barge_in: false } }

              it 'should pass the b=0 option to SynthAndRecog' do
                expect_synthandrecog_with_options(/b=0/)
                subject.execute
              end
            end
          end

          describe 'Output#voice' do
            context 'unset' do
              let(:output_command_opts) { { voice: nil } }

              it 'should not pass the vn option to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end

            context 'set' do
              let(:output_command_opts) { { voice: 'alison' } }

              it 'should pass the vn option to SynthAndRecog' do
                expect_synthandrecog_with_options(/vn=alison/)
                subject.execute
              end
            end
          end

          describe 'Output#start-offset' do
            context 'unset' do
              let(:output_command_opts) { { start_offset: nil } }
              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end

            context 'set' do
              let(:output_command_opts) { { start_offset: 10 } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A start_offset value is unsupported on Asterisk.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end
          end

          describe 'Output#start-paused' do
            context 'false' do
              let(:output_command_opts) { { start_paused: false } }
              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end

            context 'true' do
              let(:output_command_opts) { { start_paused: true } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A start_paused value is unsupported on Asterisk.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end
          end

          describe 'Output#repeat-interval' do
            context 'unset' do
              let(:output_command_opts) { { repeat_interval: nil } }
              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end

            context 'set' do
              let(:output_command_opts) { { repeat_interval: 10 } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A repeat_interval value is unsupported on Asterisk.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end
          end

          describe 'Output#repeat-times' do
            context 'unset' do
              let(:output_command_opts) { { repeat_times: nil } }
              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end

            context 'set' do
              let(:output_command_opts) { { repeat_times: 2 } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A repeat_times value is unsupported on Asterisk.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end
          end

          describe 'Output#max-time' do
            context 'unset' do
              let(:output_command_opts) { { max_time: nil } }
              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end

            context 'set' do
              let(:output_command_opts) { { max_time: 30 } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A max_time value is unsupported on Asterisk.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end
          end

          describe 'Output#interrupt_on' do
            context 'unset' do
              let(:output_command_opts) { { interrupt_on: nil } }
              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end

            context 'set' do
              let(:output_command_opts) { { interrupt_on: :dtmf } }
              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A interrupt_on value is unsupported on Asterisk.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end
          end

          describe 'Output#grammar' do
            context 'with multiple inline grammars' do
              let(:input_command_options) { { grammars: [{value: voice_grammar}, {value: dtmf_grammar}] } }

              it "should return a ref and execute SynthAndRecog" do
                param = [ssml_doc.to_doc, [voice_grammar.to_doc.to_s, dtmf_grammar.to_doc.to_s].join(',')].map { |o| "\"#{o.to_s.squish.gsub('"', '\"')}\"" }.push('uer=1&b=1').join(',')
                expect(mock_call).to receive(:execute_agi_command).once.with('EXEC SynthAndRecog', param).and_return code: 200, result: 1
                subject.execute
                expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
              end
            end

            context 'with multiple grammars by URI' do
              let(:input_command_options) { { grammars: [{url: 'http://example.com/grammar1.grxml'}, {url: 'http://example.com/grammar2.grxml'}] } }

              it "should return a ref and execute SynthAndRecog" do
                param = [ssml_doc.to_doc, ['http://example.com/grammar1.grxml', 'http://example.com/grammar2.grxml'].join(',')].map { |o| "\"#{o.to_s.squish.gsub('"', '\"')}\"" }.push('uer=1&b=1').join(',')
                expect(mock_call).to receive(:execute_agi_command).once.with('EXEC SynthAndRecog', param).and_return code: 200, result: 1
                subject.execute
                expect(original_command.response(0.1)).to be_a Adhearsion::Rayo::Ref
              end
            end

            context 'unset' do
              let(:input_command_options) { {} }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A grammar is required.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end
          end

          describe 'Input#initial-timeout' do
            context 'a positive number' do
              let(:input_command_opts) { { initial_timeout: 1000 } }

              it 'should pass the nit option to SynthAndRecog' do
                expect_synthandrecog_with_options(/nit=1000/)
                subject.execute
              end
            end

            context '-1' do
              let(:input_command_opts) { { initial_timeout: -1 } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { initial_timeout: nil } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end

            context 'a negative number other than -1' do
              let(:input_command_opts) { { initial_timeout: -1000 } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'An initial-timeout value must be -1 or a positive integer.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end
          end

          describe 'Input#recognition-timeout' do
            context 'a positive number' do
              let(:input_command_opts) { { recognition_timeout: 1000 } }

              it 'should pass the t option to SynthAndRecog' do
                expect_synthandrecog_with_options(/t=1000/)
                subject.execute
              end
            end

            context '0' do
              let(:input_command_opts) { { recognition_timeout: 0 } }

              it 'should pass the t option to SynthAndRecog' do
                expect_synthandrecog_with_options(/t=0/)
                subject.execute
              end
            end

            context 'a negative number' do
              let(:input_command_opts) { { recognition_timeout: -1000 } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A recognition-timeout value must be -1, 0, or a positive integer.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end

            context 'unset' do
              let(:input_command_opts) { { recognition_timeout: nil } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#inter-digit-timeout' do
            context 'a positive number' do
              let(:input_command_opts) { { inter_digit_timeout: 1000 } }

              it 'should pass the dit option to SynthAndRecog' do
                expect_synthandrecog_with_options(/dit=1000/)
                subject.execute
              end
            end

            context '-1' do
              let(:input_command_opts) { { inter_digit_timeout: -1 } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { inter_digit_timeout: nil } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end

            context 'a negative number other than -1' do
              let(:input_command_opts) { { inter_digit_timeout: -1000 } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'An inter-digit-timeout value must be -1 or a positive integer.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end
          end

          describe 'Input#max-silence' do
            context 'a positive number' do
              let(:input_command_opts) { { max_silence: 1000 } }

              it 'should pass the sint option to SynthAndRecog' do
                expect_synthandrecog_with_options(/sint=1000/)
                subject.execute
              end
            end

            context '0' do
              let(:input_command_opts) { { max_silence: 0 } }

              it 'should pass the sint option to SynthAndRecog' do
                expect_synthandrecog_with_options(/sint=0/)
                subject.execute
              end
            end

            context 'a negative number' do
              let(:input_command_opts) { { max_silence: -1000 } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A max-silence value must be -1, 0, or a positive integer.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end

            context 'unset' do
              let(:input_command_opts) { { max_silence: nil } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#speech-complete-timeout' do
            context 'a positive number' do
              let(:input_command_opts) { { headers: {"Speech-Complete-Timeout" => 1000 } } }

              it 'should pass the sct option to SynthAndRecog' do
                expect_synthandrecog_with_options(/sct=1000/)
                subject.execute
              end
            end

            context '0' do
              let(:input_command_opts) { { headers: {"Speech-Complete-Timeout" => 0 } } }

              it 'should pass the sct option to SynthAndRecog' do
                expect_synthandrecog_with_options(/sct=0/)
                subject.execute
              end
            end

            context 'a negative number' do
              let(:input_command_opts) { { headers: {"Speech-Complete-Timeout" => -1000 } } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A speech-complete-timeout value must be -1, 0, or a positive integer.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"Speech-Complete-Timeout" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(Speed-Vs-Accuracy)' do
            context 'a positive number' do
              let(:input_command_opts) { { headers: {"Speed-Vs-Accuracy" => 1 } } }

              it 'should pass the sva option to SynthAndRecog' do
                expect_synthandrecog_with_options(/sva=1/)
                subject.execute
              end
            end

            context '0' do
              let(:input_command_opts) { { headers: {"Speed-Vs-Accuracy" => 0 } } }

              it 'should pass the sva option to SynthAndRecog' do
                expect_synthandrecog_with_options(/sva=0/)
                subject.execute
              end
            end

            context 'a negative number' do
              let(:input_command_opts) { { headers: {"Speed-Vs-Accuracy" => -1000 } } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A speed-vs-accuracy value must be a positive integer.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"Speed-Vs-Accuracy" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(N-Best-List-Length)' do
            context 'a positive number' do
              let(:input_command_opts) { { headers: {"N-Best-List-Length" => 5 } } }

              it 'should pass the nb option to SynthAndRecog' do
                expect_synthandrecog_with_options(/nb=5/)
                subject.execute
              end
            end

            context '0' do
              let(:input_command_opts) { { headers: {"N-Best-List-Length" => 0 } } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'An n-best-list-length value must be a positive integer.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end

            context 'a negative number' do
              let(:input_command_opts) { { headers: {"N-Best-List-Length" => -1000 } } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'An n-best-list-length value must be a positive integer.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"N-Best-List-Length" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(Start-Input-Timers)' do
            context 'true' do
              let(:input_command_opts) { { headers: {"Start-Input-Timers" => true } } }

              it 'should pass the sit option to SynthAndRecog' do
                expect_synthandrecog_with_options(/sit=true/)
                subject.execute
              end
            end

            context 'false' do
              let(:input_command_opts) { { headers: {"Start-Input-Timers" => false } } }

              it 'should pass the sit option to SynthAndRecog' do
                expect_synthandrecog_with_options(/sit=false/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"Start-Input-Timers" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(DTMF-Terminate-Timeout)' do
            context 'a positive number' do
              let(:input_command_opts) { { headers: {"DTMF-Terminate-Timeout" => 1000 } } }

              it 'should pass the dtt option to SynthAndRecog' do
                expect_synthandrecog_with_options(/dtt=1000/)
                subject.execute
              end
            end

            context '0' do
              let(:input_command_opts) { { headers: {"DTMF-Terminate-Timeout" => 0 } } }

              it 'should pass the dtt option to SynthAndRecog' do
                expect_synthandrecog_with_options(/dtt=0/)
                subject.execute
              end
            end

            context 'a negative number' do
              let(:input_command_opts) { { headers: {"DTMF-Terminate-Timeout" => -1000 } } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A dtmf-terminate-timeout value must be -1, 0, or a positive integer.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"DTMF-Terminate-Timeout" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(Save-Waveform)' do
            context 'true' do
              let(:input_command_opts) { { headers: {"Save-Waveform" => true } } }

              it 'should pass the sw option to SynthAndRecog' do
                expect_synthandrecog_with_options(/sw=true/)
                subject.execute
              end
            end

            context 'false' do
              let(:input_command_opts) { { headers: {"Save-Waveform" => false } } }

              it 'should pass the sw option to SynthAndRecog' do
                expect_synthandrecog_with_options(/sw=false/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"Save-Waveform" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(New-Audio-Channel)' do
            context 'true' do
              let(:input_command_opts) { { headers: {"New-Audio-Channel" => true } } }

              it 'should pass the nac option to SynthAndRecog' do
                expect_synthandrecog_with_options(/nac=true/)
                subject.execute
              end
            end

            context 'false' do
              let(:input_command_opts) { { headers: {"New-Audio-Channel" => false } } }

              it 'should pass the nac option to SynthAndRecog' do
                expect_synthandrecog_with_options(/nac=false/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"New-Audio-Channel" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(Recognition-Mode)' do
            context 'a string' do
              let(:input_command_opts) { { headers: {"Recognition-Mode" => "hotword" } } }

              it 'should pass the rm option to SynthAndRecog' do
                expect_synthandrecog_with_options(/rm=hotword/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"Recognition-Mode" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(Hotword-Max-Duration)' do
            context 'a positive number' do
              let(:input_command_opts) { { headers: {"Hotword-Max-Duration" => 1000 } } }

              it 'should pass the hmaxd option to SynthAndRecog' do
                expect_synthandrecog_with_options(/hmaxd=1000/)
                subject.execute
              end
            end

            context '0' do
              let(:input_command_opts) { { headers: {"Hotword-Max-Duration" => 0 } } }

              it 'should pass the hmaxd option to SynthAndRecog' do
                expect_synthandrecog_with_options(/hmaxd=0/)
                subject.execute
              end
            end

            context 'a negative number' do
              let(:input_command_opts) { { headers: {"Hotword-Max-Duration" => -1000 } } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A hotword-max-duration value must be -1, 0, or a positive integer.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"Hotword-Max-Duration" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(Hotword-Min-Duration)' do
            context 'a positive number' do
              let(:input_command_opts) { { headers: {"Hotword-Min-Duration" => 1000 } } }

              it 'should pass the hmind option to SynthAndRecog' do
                expect_synthandrecog_with_options(/hmind=1000/)
                subject.execute
              end
            end

            context '0' do
              let(:input_command_opts) { { headers: {"Hotword-Min-Duration" => 0 } } }

              it 'should pass the hmind option to SynthAndRecog' do
                expect_synthandrecog_with_options(/hmind=0/)
                subject.execute
              end
            end

            context 'a negative number' do
              let(:input_command_opts) { { headers: {"Hotword-Min-Duration" => -1000 } } }

              it "should return an error and not execute any actions" do
                subject.execute
                error = Adhearsion::ProtocolError.new.setup 'option error', 'A hotword-min-duration value must be -1, 0, or a positive integer.'
                expect(original_command.response(0.1)).to eq(error)
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"Hotword-Min-Duration" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(Clear-DTMF-Buffer)' do
            context 'true' do
              let(:input_command_opts) { { headers: {"Clear-DTMF-Buffer" => true } } }

              it 'should pass the cdb option to SynthAndRecog' do
                expect_synthandrecog_with_options(/cdb=true/)
                subject.execute
              end
            end

            context 'false' do
              let(:input_command_opts) { { headers: {"Clear-DTMF-Buffer" => false } } }

              it 'should pass the cdb option to SynthAndRecog' do
                expect_synthandrecog_with_options(/cdb=false/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"Clear-DTMF-Buffer" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(Early-No-Match)' do
            context 'true' do
              let(:input_command_opts) { { headers: {"Early-No-Match" => true } } }

              it 'should pass the enm option to SynthAndRecog' do
                expect_synthandrecog_with_options(/enm=true/)
                subject.execute
              end
            end

            context 'a negative number' do
              let(:input_command_opts) { { headers: {"Early-No-Match" => false } } }

              it "should return an error and not execute any actions" do
                expect_synthandrecog_with_options(/enm=false/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"Early-No-Match" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(Input-Waveform-URI)' do
            context 'a positive number' do
              let(:input_command_opts) { { headers: {"Input-Waveform-URI" => 'http://wave.form.com' } } }

              it 'should pass the iwu option to SynthAndRecog' do
                expect_synthandrecog_with_options(/iwu=http:\/\/wave\.form\.com/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"Input-Waveform-URI" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#headers(Media-Type)' do
            context 'a string' do
              let(:input_command_opts) { { headers: {"Media-Type" => "foo/type" } } }

              it 'should pass the mt option to SynthAndRecog' do
                expect_synthandrecog_with_options(/mt=foo\/type/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { headers: {"Media-Type" => nil } } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#mode' do
            skip
          end

          describe 'Input#terminator' do
            context 'a string' do
              let(:input_command_opts) { { terminator: '#' } }

              it 'should pass the dttc option to SynthAndRecog' do
                expect_synthandrecog_with_options(/dttc=#/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { terminator: nil } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#recognizer' do
            skip
          end

          describe 'Input#sensitivity' do
            context 'a string' do
              let(:input_command_opts) { { sensitivity: '0.2' } }

              it 'should pass the sl option to SynthAndRecog' do
                expect_synthandrecog_with_options(/sl=0.2/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { sensitivity: nil } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#min-confidence' do
            context 'a string' do
              let(:input_command_opts) { { min_confidence: '0.5' } }

              it 'should pass the ct option to SynthAndRecog' do
                expect_synthandrecog_with_options(/ct=0.5/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { min_confidence: nil } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
            end
          end

          describe 'Input#max-silence' do
            skip
          end

          describe 'Input#match-content-type' do
            skip
          end

          describe 'Input#language' do
            context 'a string' do
              let(:input_command_opts) { { language: 'en-GB' } }

              it 'should pass the spl option to SynthAndRecog' do
                expect_synthandrecog_with_options(/spl=en-GB/)
                subject.execute
              end
            end

            context 'unset' do
              let(:input_command_opts) { { language: nil } }

              it 'should not pass any options to SynthAndRecog' do
                expect_synthandrecog_with_options(//)
                subject.execute
              end
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
              let(:channel) { "SIP/1234-00000000" }
              let :ami_event do
                RubyAMI::Event.new 'AsyncAGI',
                  'SubEvent'  => "Start",
                  'Channel'   => channel,
                  'Env'       => "agi_request%3A%20async%0Aagi_channel%3A%20SIP%2F1234-00000000%0Aagi_language%3A%20en%0Aagi_type%3A%20SIP%0Aagi_uniqueid%3A%201320835995.0%0Aagi_version%3A%201.8.4.1%0Aagi_callerid%3A%205678%0Aagi_calleridname%3A%20Jane%20Smith%0Aagi_callingpres%3A%200%0Aagi_callingani2%3A%200%0Aagi_callington%3A%200%0Aagi_callingtns%3A%200%0Aagi_dnid%3A%201000%0Aagi_rdnis%3A%20unknown%0Aagi_context%3A%20default%0Aagi_extension%3A%201000%0Aagi_priority%3A%201%0Aagi_enhanced%3A%200.0%0Aagi_accountcode%3A%20%0Aagi_threadid%3A%204366221312%0A%0A"
              end

              before do
                command.request!
                original_command.execute!
              end

              it "sets the command response to true" do
                expect(mock_call).to receive(:redirect_back)
                subject.execute_command command
                expect(command.response(0.1)).to eq(true)
              end

              it "sends the correct complete event" do
                expect(mock_call).to receive(:redirect_back)
                subject.execute_command command
                expect(original_command).not_to be_complete
                mock_call.process_ami_event ami_event
                expect(reason).to be_a Adhearsion::Event::Complete::Stop
                expect(original_command).to be_complete
              end

              it "redirects the call by unjoining it" do
                expect(mock_call).to receive(:redirect_back)
                subject.execute_command command
              end
            end
          end

        end
      end
    end
  end
end
