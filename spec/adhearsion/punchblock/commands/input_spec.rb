require 'spec_helper'

module Adhearsion
  module Punchblock
    module Commands
      describe Input do
        include PunchblockCommandTestHelpers

        describe "#grammar_digits" do 
          let(:grxml) {
            RubySpeech::GRXML.draw do
              self.mode = 'dtmf'
              self.root = 'inputdigits'
              rule id: 'digits' do
                one_of do
                  0.upto(9) {|d| item { d.to_s } }
                end
              end

              rule id: 'inputdigits', scope: 'public' do
                item repeat: '2' do
                  ruleref uri: '#digits'
                end
              end
            end
          }
          
          it 'generates the correct GRXML grammar' do
            mock_execution_environment.grammar_digits(2).to_s.should == grxml.to_s 
          end#it

        end#describe #grammar_digits

        describe "#grammar_accept" do
          let(:grxml) {
            RubySpeech::GRXML.draw do
              self.mode = 'dtmf'
              self.root = 'inputdigits'
              rule id: 'acceptdigits' do
                one_of do
                  item {'3'}
                  item {'5'}
                end
              end

              rule id: 'inputdigits', scope: 'public' do
                item repeat: '1' do
                  ruleref uri: '#acceptdigits'
                end
              end

            end
          }

          it 'generates the correct GRXML grammar' do
            mock_execution_environment.grammar_accept('35').to_s.should == grxml.to_s 
          end#it

          it 'filters meaningless characters out' do
            mock_execution_environment.grammar_accept('3+5').to_s.should == grxml.to_s 
          end#it
        end#grammar_accept

        describe "#parse_single_dtmf"  do
          it "correctly returns the parsed input" do
            mock_execution_environment.parse_single_dtmf("dtmf-3").should == '3'
          end
          it "correctly returns star as *" do
            mock_execution_environment.parse_single_dtmf("dtmf-star").should == '*'
          end
          it "correctly returns pound as #" do
            mock_execution_environment.parse_single_dtmf("dtmf-pound").should == '#'
          end
          it "correctly returns nil when input is nil" do
            mock_execution_environment.parse_single_dtmf(nil).should == nil
          end
        end#describe #grammar_accept

        describe "#wait_for_digit" do
          let(:timeout) { 2000 }

          let(:grxml) {
            RubySpeech::GRXML.draw do
              self.mode = 'dtmf'
              self.root = 'inputdigits'
              rule id: 'acceptdigits' do
                one_of do
                  0.upto(9) {|d| item { d.to_s } }
                  item {"#"}
                  item {"*"}
                end
              end
              rule id: 'inputdigits', scope: 'public' do
                item repeat: '1' do
                  ruleref uri: '#acceptdigits'
                end
              end
            end
          }

          let(:input_component) {
            Punchblock::Component::Input.new(
              { :mode => :dtmf,
                :initial_timeout => timeout,
                :inter_digit_timeout => timeout,
                :grammar => {
                  :value => grxml.to_s
                }
              }
            )
          }

          it "sends the correct input component" do
            mock_execution_environment.should_receive(:execute_component_and_await_completion).once.with(input_component)
            mock_execution_environment.wait_for_digit(timeout)
          end

          it "returns the correct pressed digit" do
            flexmock(Punchblock::Event::Complete).new_instances.should_receive(:reason => flexmock(:interpretation => 'dtmf-5', :name => :input))
            # def mock_execution_environment.execute_component_and_await_completion(input_component)
            def mock_execution_environment.write_and_await_response(input_component)
              input_component.execute_handler
            end
            flexmock(Punchblock::Component::Input).new_instances do |input|
              input.should_receive(:complete?).and_return(false)
            end
            
            mock_execution_environment.should_receive(:execute_component_and_await_completion).once.with(input_component)
            mock_execution_environment.wait_for_digit(timeout).should == '5'
          end
        end#wait_for_digit

     end#describe Input
    end
  end
end
