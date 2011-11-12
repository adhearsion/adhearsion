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

            def expect_component_complete_event
              complete_event = Punchblock::Event::Complete.new
              flexmock(complete_event).should_receive(:reason => flexmock(:interpretation => 'dtmf-5', :name => :input))
              flexmock(Punchblock::Component::Input).new_instances do |input|
                input.should_receive(:complete?).and_return(false)
                input.should_receive(:complete_event).and_return(flexmock('FutureResource', :resource => complete_event))
              end
            end

            it "sends the correct input component" do
              expect_component_complete_event
              mock_execution_environment.should_receive(:execute_component_and_await_completion).once.with(input_component).and_return input_component
              mock_execution_environment.wait_for_digit timeout
            end

            it "returns the correct pressed digit" do
              expect_component_complete_event
              mock_execution_environment.should_receive(:execute_component_and_await_completion).once.with(Punchblock::Component::Input).and_return input_component
              mock_execution_environment.wait_for_digit(timeout).should == '5'
            end
        end#wait_for_digit

        describe "#input!" do
          
          describe "simple usage" do
            let(:timeout) { 3000 }
            
            it "can be called with no arguments" do
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('1')
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('#')
              mock_execution_environment.input!()
            end

            it "can be called with 1 digit as an argument" do
              mock_execution_environment.should_receive(:wait_for_digit).with(nil)
              mock_execution_environment.input!(1)
            end

            it "accepts a timeout argument" do
              mock_execution_environment.should_receive(:wait_for_digit).with(3000)
              mock_execution_environment.input!(:timeout => timeout)
            end
          end

          describe "any number of digits with an accept key" do
            let(:accept_key) { '9' }
            
            it "called with no arguments, it returns any number of digits taking a accept key" do
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('1')
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('#')
              mock_execution_environment.input!().should == '1'
            end
            
            it "allows to set a different accept key" do
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('1')
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return(accept_key)
              mock_execution_environment.input!(:accept_key => accept_key).should == '1'
            end
          end

          describe "with a fixed number or digits" do
            it "accepts and returns three digits without an accept key" do
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('1')
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('2')
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('3')
              mock_execution_environment.input!(3).should == '123'
            end
          end

          describe "with play arguments" do
            let(:string_play) { "Thanks for calling" }
            let(:ssml_play) { RubySpeech::SSML.draw { string "Please stand by" } }
            let(:hash_play) { {:value => Time.parse("24/10/2011"), :strftime => "%H:%M"} } 
            let(:hash_value) { Time.parse("24/10/2011") }
            let(:hash_options) { {:strftime => "%H:%M"} } 

            it "plays a string argument" do
              mock_execution_environment.should_receive(:interruptible_play!).with(string_play)
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('#')
              mock_execution_environment.input!(:play => string_play)
            end

            it "plays a SSML argument" do
              mock_execution_environment.should_receive(:interruptible_play!).with(ssml_play)
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('#')
              mock_execution_environment.input!(:play => ssml_play)
            end

            it "plays a Hash argument" do
              mock_execution_environment.should_receive(:interruptible_play!).with([hash_value, hash_options])
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('#')
              mock_execution_environment.input!(:play => hash_play)
            end

            it "plays an array of mixed arguments" do
              mock_execution_environment.should_receive(:interruptible_play!).with(string_play)
              mock_execution_environment.should_receive(:interruptible_play!).with(ssml_play)
              mock_execution_environment.should_receive(:interruptible_play!).with([hash_value, hash_options])
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('#')
              mock_execution_environment.input!(:play => [string_play, ssml_play, hash_play])
            end

            it "plays a string argument, takes 1 digit and returns the input" do
              mock_execution_environment.should_receive(:interruptible_play!).with(string_play).and_return('1')
              mock_execution_environment.input!(1, :play => string_play).should == '1'
            end

            it "plays a string argument, takes 2 digits and returns the input" do
              mock_execution_environment.should_receive(:interruptible_play!).with(string_play).and_return('1')
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('1')
              mock_execution_environment.input!(2, :play => string_play).should == '11'
            end

            it "plays a string argument, allows for any number of digit and an accept key" do
              mock_execution_environment.should_receive(:interruptible_play!).with(string_play).and_return('1').ordered
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('2').ordered
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('#').ordered
              mock_execution_environment.input!(:play => string_play).should == '12'
            end

            it "plays an array of mixed arguments, stops playing when a key is pressed, and returns the input" do
              mock_execution_environment.should_receive(:interruptible_play!).with(string_play).and_return(nil)
              mock_execution_environment.should_receive(:interruptible_play!).with(ssml_play).and_return('1')
              # mock_execution_environment.should_not_receive(:interruptible_play!).with([hash_value, hash_options])
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('#')
              mock_execution_environment.input!(:play => [string_play, ssml_play, hash_play]).should == '1'
            end

          end#describe with play arguments

          describe "non interruptible play" do
            let(:string_play) { "Thanks for calling" }

            it "calls play! when passed :interruptible => false" do
              mock_execution_environment.should_receive(:play!).with(string_play)
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('#')
              mock_execution_environment.input!(:play => string_play, :interruptible => false)
            end

            it "still collects digits when passed :interruptible => false" do
              mock_execution_environment.should_receive(:play!).with(string_play)
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('1')
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('#')
              mock_execution_environment.input!(:play => string_play, :interruptible => false).should == '1'
            end
          end#describe non interruptible play

          describe "speak functionality" do
            let(:string_speak) { "Thanks for calling" }
    
            it "speaks passed text" do
              mock_execution_environment.should_receive(:interruptible_play!).with(string_speak, {})
              mock_execution_environment.input!(:speak => {:text => string_speak })
            end

            it "speaks passed text and collect digits" do
              mock_execution_environment.should_receive(:interruptible_play!).with(string_speak, {}).and_return('1')
              mock_execution_environment.should_receive(:wait_for_digit).once.with(nil).and_return('#')
              mock_execution_environment.input!(:speak => {:text => string_speak }).should == '1'
            end
          end
        end#describe input!


     end#describe Input
    end
  end
end
