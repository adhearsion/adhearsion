require 'spec_helper'

module Adhearsion
  class CallController
    describe Input do
      include CallControllerTestHelpers

      describe "#grammar_digits" do
        let(:grxml) {
          RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'inputdigits' do
            rule id: 'inputdigits', scope: 'public' do
              item repeat: '2' do
                one_of do
                  0.upto(9) { |d| item { d.to_s } }
                end
              end
            end
          end
        }

        it 'generates the correct GRXML grammar' do
          subject.grammar_digits(2).to_s.should == grxml.to_s
        end

      end # describe #grammar_digits

      describe "#grammar_accept" do
        let(:grxml) {
          RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'inputdigits' do
            rule id: 'inputdigits', scope: 'public' do
              one_of do
                item { '3' }
                item { '5' }
              end
            end
          end
        }

        it 'generates the correct GRXML grammar' do
          subject.grammar_accept('35').to_s.should == grxml.to_s
        end

        it 'filters meaningless characters out' do
          subject.grammar_accept('3+5').to_s.should == grxml.to_s
        end
      end # grammar_accept

      describe "#parse_single_dtmf"  do
        it "correctly returns the parsed input" do
          subject.parse_single_dtmf("dtmf-3").should == '3'
        end

        it "correctly returns star as *" do
          subject.parse_single_dtmf("dtmf-star").should == '*'
        end

        it "correctly returns pound as #" do
          subject.parse_single_dtmf("dtmf-pound").should == '#'
        end

        it "correctly returns nil when input is nil" do
          subject.parse_single_dtmf(nil).should == nil
        end
      end # describe #grammar_accept

      describe "#wait_for_digit" do
        let(:timeout) { 2 }
        let(:timeout_ms) { 2000 }

        let(:grxml) {
          RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'inputdigits' do
            rule id: 'inputdigits', scope: 'public' do
              one_of do
                0.upto(9) { |d| item { d.to_s } }
                item { "#" }
                item { "*" }
              end
            end
          end
        }

        let(:input_component) {
          Punchblock::Component::Input.new(
            { :mode => :dtmf,
              :initial_timeout => timeout_ms,
              :inter_digit_timeout => timeout_ms,
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
            input.should_receive(:complete_event).and_return(complete_event)
          end
        end

        it "sends the correct input component" do
          expect_component_complete_event
          subject.should_receive(:execute_component_and_await_completion).once.with(input_component).and_return input_component
          subject.wait_for_digit timeout
        end

        it "returns the correct pressed digit" do
          expect_component_complete_event
          subject.should_receive(:execute_component_and_await_completion).once.with(Punchblock::Component::Input).and_return input_component
          subject.wait_for_digit(timeout).should == '5'
        end

        context "with a nil timeout" do
          let(:timeout)     { nil }
          let(:timeout_ms)  { nil }

          it "does not set a timeout on the component" do
            expect_component_complete_event
            subject.should_receive(:execute_component_and_await_completion).once.with(input_component).and_return input_component
            subject.wait_for_digit timeout
          end
        end
      end # wait_for_digit

      describe "#input!" do
        describe "simple usage" do
          let(:timeout) { 3000 }

          it "can be called with no arguments" do
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('1')
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('#')
            subject.input!
          end

          it "can be called with 1 digit as an argument" do
            subject.should_receive(:wait_for_digit).with(nil)
            subject.input! 1
          end

          it "accepts a timeout argument" do
            subject.should_receive(:wait_for_digit).with(3000)
            subject.input! :timeout => timeout
          end
        end

        describe "any number of digits with a terminator" do
          let(:terminator) { '9' }

          it "called with no arguments, it returns any number of digits taking a terminating digit" do
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('1')
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('#')
            subject.input!.should == '1'
          end

          it "allows to set a different terminator" do
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('1')
            subject.should_receive(:wait_for_digit).once.with(nil).and_return(terminator)
            subject.input!(:terminator => terminator).should == '1'
          end
        end

        describe "with a fixed number or digits" do
          it "accepts and returns three digits without a terminator" do
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('1')
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('2')
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('3')
            subject.input!(3).should == '123'
          end
        end

        describe "with play arguments" do
          let(:string_play)   { "Thanks for calling" }
          let(:ssml_play)     { RubySpeech::SSML.draw { string "Please stand by" } }
          let(:hash_play)     { {:value => Time.parse("24/10/2011"), :strftime => "%H:%M"} }
          let(:hash_value)    { Time.parse "24/10/2011" }
          let(:hash_options)  { {:strftime => "%H:%M"} }

          it "plays a string argument" do
            subject.should_receive(:interruptible_play!).with(string_play)
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('#')
            subject.input! :play => string_play
          end

          it "plays a SSML argument" do
            subject.should_receive(:interruptible_play!).with(ssml_play)
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('#')
            subject.input! :play => ssml_play
          end

          it "plays a Hash argument" do
            subject.should_receive(:interruptible_play!).with([hash_value, hash_options])
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('#')
            subject.input! :play => hash_play
          end

          it "plays an array of mixed arguments" do
            subject.should_receive(:interruptible_play!).with(string_play)
            subject.should_receive(:interruptible_play!).with(ssml_play)
            subject.should_receive(:interruptible_play!).with([hash_value, hash_options])
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('#')
            subject.input! :play => [string_play, ssml_play, hash_play]
          end

          it "plays a string argument, takes 1 digit and returns the input" do
            subject.should_receive(:interruptible_play!).with(string_play).and_return('1')
            subject.input!(1, :play => string_play).should == '1'
          end

          it "plays a string argument, takes 2 digits and returns the input" do
            subject.should_receive(:interruptible_play!).with(string_play).and_return('1')
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('1')
            subject.input!(2, :play => string_play).should == '11'
          end

          it "plays a string argument, allows for any number of digit and an accept key" do
            subject.should_receive(:interruptible_play!).with(string_play).and_return('1').ordered
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('2').ordered
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('#').ordered
            subject.input!(:play => string_play).should == '12'
          end

          it "plays an array of mixed arguments, stops playing when a key is pressed, and returns the input" do
            subject.should_receive(:interruptible_play!).and_return(nil, '1', StandardError.new("should not be called"))
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('#')
            subject.input!(:play => [string_play, ssml_play, hash_play]).should == '1'
          end
        end # describe with play arguments

        describe "non interruptible play" do
          let(:string_play) { "Thanks for calling" }

          it "calls play! when passed :interruptible => false" do
            subject.should_receive(:play!).with(string_play)
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('#')
            subject.input! :play => string_play, :interruptible => false
          end

          it "still collects digits when passed :interruptible => false" do
            subject.should_receive(:play!).with(string_play)
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('1')
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('#')
            subject.input!(:play => string_play, :interruptible => false).should == '1'
          end
        end # describe non interruptible play

        describe "speak functionality" do
          let(:string_speak) { "Thanks for calling" }

          it "speaks passed text" do
            subject.should_receive(:interruptible_play!).with(string_speak, {})
            subject.input! :speak => {:text => string_speak }
          end

          it "speaks passed text and collect digits" do
            subject.should_receive(:interruptible_play!).with(string_speak, {}).and_return('1')
            subject.should_receive(:wait_for_digit).once.with(nil).and_return('#')
            subject.input!(:speak => {:text => string_speak }).should == '1'
          end
        end

        it 'throws an exception when playback fails'
      end # describe input!

      describe "#input" do
        let(:string_play) { "Thanks for calling" }

        it "just calls #input!" do
          subject.should_receive(:input!).with(:play => string_play).and_return(nil)
          subject.input! :play => string_play
        end

        it 'does not throw exceptions when playback fails'
      end # describe input
    end
  end
end
