# encoding: utf-8

require 'spec_helper'

module Adhearsion
  module MenuDSL
    describe Menu do

        let(:options) { Hash.new }
        subject { Menu.new(options) {}  }

        describe "#initialize" do

          its(:tries_count) { should == 0 }


          context 'when no timeout is set' do
            it "should have the default timeout" do
              subject.timeout.should == 5
            end
          end
          context 'when a timeout is set' do
            let(:options) {
              {:timeout => 20}
            }
            it 'should have the passed timeout' do
              subject.timeout.should == 20
            end
          end

          context 'when no max number of tries is set' do
            it "should have the default max number of tries" do
              subject.max_number_of_tries.should == 1
            end
          end
          context 'when a max number of tries is set' do
            let(:options) {
              {:tries => 3}
            }
            it 'should have the passed max number of tries' do
              subject.max_number_of_tries.should == 3
            end
          end

          context 'menu builder setup' do
            its(:builder) { should be_a MenuBuilder }

            it "should evaluate the block on the builder object" do
              mock_menu_builder = flexmock(MenuBuilder.new)
              flexmock(MenuBuilder).should_receive(:new).and_return(mock_menu_builder)
              mock_menu_builder.should_receive(:match).once.with(1)
              Menu.new {match 1}
            end
          end

        end # describe #initialize

        describe "#digit_buffer" do
          its(:digit_buffer) { should be_a Menu::ClearableStringBuffer }
          its(:digit_buffer) { should == "" }
        end

        describe "#<<" do
          it "should add a digit to the buffer" do
            subject << 'a'
            subject.digit_buffer.should == 'a'
          end
        end

        describe "#digit_buffer_empty?" do
          it "returns true if buffer is empty" do
            subject.digit_buffer_empty?.should == true
          end
          it "returns false if buffer is not empty" do
            subject << 1
            subject.digit_buffer_empty?.should == false
          end
        end

        describe "#digit_buffer_string" do
          it "returns the digit buffer as a string" do
            subject << 1
            subject.digit_buffer_string.should == "1"
          end
        end

        describe "#should_continue?" do
          it "returns true if the number of tries is less than the maximum" do
            subject.max_number_of_tries.should == 1
            subject.tries_count.should == 0
            subject.should_continue?.should == true
          end
        end

        describe "#restart!" do
          it "increments tries and clears the digit buffer" do
            subject << 1
            subject.restart!
            subject.tries_count.should == 1
            subject.digit_buffer_empty?.should == true
          end
        end

        describe "#execute_invalid_hook" do
          it "calls the builder's execute_hook_for with :invalid" do
            mock_menu_builder = flexmock(MenuBuilder.new)
            flexmock(MenuBuilder).should_receive(:new).and_return(mock_menu_builder)
            mock_menu_builder.should_receive(:execute_hook_for).with(:invalid, "")
            menu_instance = Menu.new() {}
            menu_instance.execute_invalid_hook
          end
        end

        describe "#execute_timeout_hook" do
          it "calls the builder's execute_hook_for with :timeout" do
            mock_menu_builder = flexmock(MenuBuilder.new)
            flexmock(MenuBuilder).should_receive(:new).and_return(mock_menu_builder)
            mock_menu_builder.should_receive(:execute_hook_for).with(:timeout, "")
            menu_instance = Menu.new() {}
            menu_instance.execute_timeout_hook
          end
        end

        describe "#execute_failure_hook" do
          it "calls the builder's execute_hook_for with :failure" do
            mock_menu_builder = flexmock(MenuBuilder.new)
            flexmock(MenuBuilder).should_receive(:new).and_return(mock_menu_builder)
            mock_menu_builder.should_receive(:execute_hook_for).with(:failure, "")
            menu_instance = Menu.new() {}
            menu_instance.execute_failure_hook
          end
        end

        describe "#continue" do
          class MockControllerA; end
          class MockControllerB; end
          class MockControllerC; end
          let(:menu_instance) {
            Menu.new do
              match 1, MockControllerA
              match 21, MockControllerA
              match 23, MockControllerA
              match 3, MockControllerB
              match 3..5, MockControllerC
              match 33, MockControllerA
              match 6, MockControllerC
              match 6..8, MockControllerA
            end
          }
          it "returns a MenuGetAnotherDigitOrTimeout if the digit buffer is empty" do
            subject.continue.should be_a Menu::MenuGetAnotherDigitOrTimeout
          end

          it "asks for another digit if it has potential matches" do
            menu_instance << 2
            menu_instance.continue.should be_a Menu::MenuGetAnotherDigitOrTimeout 
          end

          it "returns a MenuResultInvalid if there are no matches" do
            menu_instance << 9
            menu_instance.continue.should be_a Menu::MenuResultInvalid
          end

          it "returns a MenuGetAnotherDigitOrFinish if it has exact and potential matches" do
            menu_instance << 3
            menu_result = menu_instance.continue
            menu_result.should be_a Menu::MenuGetAnotherDigitOrFinish
          end

          it "returns the first exact match when it has exact and potentials" do
            menu_instance << 3
            menu_result = menu_instance.continue
            menu_result.should be_a Menu::MenuGetAnotherDigitOrFinish
            menu_result.match_object.should == MockControllerB
            menu_result.new_extension.should == "3"
          end

          it "returns a MenuResultFound if it has exact matches" do
            menu_instance << 6
            menu_result = menu_instance.continue
            menu_result.should be_a Menu::MenuResultFound
          end

          it "returns the first exact match when it has only exact matches" do
            menu_instance << 6
            menu_result = menu_instance.continue
            menu_result.should be_a Menu::MenuResultFound
            menu_result.match_object.match_payload.should == MockControllerC
            menu_result.match_object.pattern.to_s.should == "6"
          end

        end#continue

        describe Menu::ClearableStringBuffer do
          subject { Menu::ClearableStringBuffer.new }

          it "adds a string to itself" do
            subject << 'b'
            subject << 'c'
            subject.should == 'bc'
          end

          it "clears itself" do
            subject << 'a'
            subject.clear!
            subject.should == ""
          end
        end

    end # describe Menu
  end
end
