# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    module MenuDSL
      describe Menu do

          let(:options) { Hash.new }
          subject { Menu.new(options) }

          describe "#initialize" do
            describe '#tries_count' do
              subject { super().tries_count }
              it { is_expected.to eq(0) }
            end

            context 'when no timeout is set' do
              it "should have the default timeout" do
                expect(subject.timeout).to eq(5)
              end
            end

            context 'when a timeout is set' do
              let(:options) {
                {:timeout => 20}
              }

              it 'should have the passed timeout' do
                expect(subject.timeout).to eq(20)
              end
            end

            context 'when no max number of tries is set' do
              it "should have the default max number of tries" do
                expect(subject.max_number_of_tries).to eq(1)
              end
            end

            context 'when a max number of tries is set' do
              let(:options) {
                {:tries => 3}
              }

              it 'should have the passed max number of tries' do
                expect(subject.max_number_of_tries).to eq(3)
              end
            end

            context 'when no terminator is set' do
              it "should have no terminator" do
                expect(subject.terminator).to eq('')
              end

              it 'should not validate successfully' do
                expect { subject.validate }.to raise_error(Menu::InvalidStructureError)
              end
            end

            context 'when a terminator is set' do
              let(:options) {
                {:terminator => 3}
              }

              it 'should have the passed terminator' do
                expect(subject.terminator).to eq('3')
              end

              it 'should validate(:basic) successfully' do
                expect(subject.validate(:basic)).to be true
              end

              it 'should not validate successfully' do
                expect { subject.validate }.to raise_error(Menu::InvalidStructureError)
              end
            end

            context 'when no limit is set' do
              it "should have no limit" do
                expect(subject.limit).to be nil
              end

              it 'should not validate successfully' do
                expect { subject.validate }.to raise_error(Menu::InvalidStructureError)
              end
            end

            context 'when a limit is set' do
              let(:options) {
                {:limit => 3}
              }

              it 'should have the passed limit' do
                expect(subject.limit).to eq(3)
              end

              it 'should validate(:basic) successfully' do
                expect(subject.validate(:basic)).to be true
              end

              it 'should not validate successfully' do
                expect { subject.validate }.to raise_error(Menu::InvalidStructureError)
              end
            end

            context 'when no interruptibility is set' do
              it "should be interruptible" do
                expect(subject.interruptible).to be true
              end
            end

            context 'when interruptible is set false' do
              let(:options) {
                {:interruptible => false}
              }

              it 'should be interruptible' do
                expect(subject.interruptible).to be false
              end
            end

            context 'when renderer is not specified' do
              it 'should have a nil renderer' do
                expect(subject.renderer).to be nil
              end
            end

            context 'when renderer is specified' do
              let(:options) {
                {:renderer => :native}
              }

              it 'should have the specified renderer' do
                expect(subject.renderer).to eq(:native)
              end
            end

            context 'when matchers are specified' do
              subject do
                Menu.new do
                  match(1) { }
                end
              end

              it 'should validate successfully' do
                expect(subject.validate).to be true
              end

              it 'should not validate(:basic) successfully' do
                expect { subject.validate :basic }.to raise_error(Menu::InvalidStructureError)
              end
            end

            context 'menu builder setup' do
              describe '#builder' do
                subject { super().builder }
                it { is_expected.to be_a MenuBuilder }
              end

              it "should evaluate the block on the builder object" do
                mock_menu_builder = MenuBuilder.new
                expect(MenuBuilder).to receive(:new).and_return(mock_menu_builder)
                expect(mock_menu_builder).to receive(:match).once.with(1)
                Menu.new { match 1 }
              end
            end

          end # describe #initialize

          describe "#digit_buffer" do
            describe '#digit_buffer' do
              subject { super().digit_buffer }
              it { is_expected.to be_a Menu::ClearableStringBuffer }
            end

            describe '#digit_buffer' do
              subject { super().digit_buffer }
              it { is_expected.to eq("") }
            end
          end

          describe "#<<" do
            it "should add a digit to the buffer" do
              subject << 'a'
              expect(subject.digit_buffer).to eq('a')
              expect(subject.result).to eq('a')
            end
          end

          describe "#digit_buffer_empty?" do
            it "returns true if buffer is empty" do
              expect(subject.digit_buffer_empty?).to eq(true)
            end

            it "returns false if buffer is not empty" do
              subject << 1
              expect(subject.digit_buffer_empty?).to eq(false)
            end
          end

          describe "#digit_buffer_string" do
            it "returns the digit buffer as a string" do
              subject << 1
              expect(subject.digit_buffer_string).to eq("1")
            end
          end

          describe "#should_continue?" do
            it "returns true if the number of tries is less than the maximum" do
              expect(subject.max_number_of_tries).to eq(1)
              expect(subject.tries_count).to eq(0)
              expect(subject.should_continue?).to eq(true)
            end
          end

          describe "#restart!" do
            it "increments tries and clears the digit buffer" do
              subject << 1
              subject.restart!
              expect(subject.tries_count).to eq(1)
              expect(subject.digit_buffer_empty?).to eq(true)
            end
          end

          describe "#execute_invalid_hook" do
            it "calls the builder's execute_hook_for with :invalid" do
              mock_menu_builder = MenuBuilder.new
              expect(MenuBuilder).to receive(:new).and_return(mock_menu_builder)
              expect(mock_menu_builder).to receive(:execute_hook_for).with(:invalid, "")
              menu_instance = Menu.new
              menu_instance.execute_invalid_hook
            end
          end

          describe "#execute_timeout_hook" do
            it "calls the builder's execute_hook_for with :timeout" do
              mock_menu_builder = MenuBuilder.new
              expect(MenuBuilder).to receive(:new).and_return(mock_menu_builder)
              expect(mock_menu_builder).to receive(:execute_hook_for).with(:timeout, "")
              menu_instance = Menu.new
              menu_instance.execute_timeout_hook
            end
          end

          describe "#execute_failure_hook" do
            it "calls the builder's execute_hook_for with :failure" do
              mock_menu_builder = MenuBuilder.new
              expect(MenuBuilder).to receive(:new).and_return(mock_menu_builder)
              expect(mock_menu_builder).to receive(:execute_hook_for).with(:failure, "")
              menu_instance = Menu.new
              menu_instance.execute_failure_hook
            end
          end

          describe "#execute_validator_hook" do
            it "calls the builder's execute_hook_for with :validator" do
              mock_menu_builder = MenuBuilder.new
              expect(MenuBuilder).to receive(:new).and_return(mock_menu_builder)
              expect(mock_menu_builder).to receive(:execute_hook_for).with(:validator, "")
              menu_instance = Menu.new
              menu_instance.execute_validator_hook
            end
          end

          describe "#continue" do
            class MockControllerA; end
            class MockControllerB; end
            class MockControllerC; end
            let(:options) { {} }
            let(:menu_instance) {
              Menu.new options do
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
              expect(subject.continue).to be_a Menu::MenuGetAnotherDigitOrTimeout
              expect(menu_instance.status).to be nil
            end

            it "asks for another digit if it has potential matches" do
              menu_instance << 2
              expect(menu_instance.continue).to be_a Menu::MenuGetAnotherDigitOrTimeout
              expect(menu_instance.status).to eq(:potential)
            end

            it "returns a MenuResultInvalid if there are no matches" do
              menu_instance << 9
              expect(menu_instance.continue).to be_a Menu::MenuResultInvalid
              expect(menu_instance.status).to eq(:invalid)
            end

            it "returns the first exact match when it has exact and potentials" do
              menu_instance << 3
              menu_result = menu_instance.continue
              expect(menu_result).to be_a Menu::MenuGetAnotherDigitOrFinish
              expect(menu_result.match_object).to eq(MockControllerB)
              expect(menu_result.new_extension).to eq("3")
              expect(menu_instance.status).to eq(:multi_matched)
            end

            it "returns a MenuResultFound if it has exact matches" do
              menu_instance << 6
              menu_result = menu_instance.continue
              expect(menu_result).to be_a Menu::MenuResultFound
              expect(menu_instance.status).to eq(:matched)
            end

            it "returns the first exact match when it has only exact matches" do
              menu_instance << 6
              menu_result = menu_instance.continue
              expect(menu_result).to be_a Menu::MenuResultFound
              expect(menu_result.match_object.match_payload).to eq(MockControllerC)
              expect(menu_result.match_object.pattern.to_s).to eq("6")
            end

            context "with no matchers" do
              let(:menu_instance) { Menu.new options }

              context "when a terminator digit is set" do
                let(:options) { { :terminator => '#' } }

                it "buffers until the terminator is issued then returns a MenuTerminated and sets the status to :terminated, removing the terminator from the buffer" do
                  menu_instance << 2
                  menu_instance << 4
                  expect(menu_instance.continue).to be_a Menu::MenuGetAnotherDigitOrTimeout
                  expect(menu_instance.status).to eq(:potential)
                  menu_instance << '#'
                  expect(menu_instance.continue).to be_a Menu::MenuTerminated
                  expect(menu_instance.continue).to be_a Menu::MenuResultDone
                  expect(menu_instance.status).to eq(:terminated)
                  expect(menu_instance.result).to eq('24')
                end
              end

              context "when a digit limit is set" do
                let(:options) { { :limit => 3 } }

                it "buffers until the limit is reached, then returns MenuLimitReached and sets the status to :limited" do
                  menu_instance << 2
                  menu_instance << 4
                  expect(menu_instance.continue).to be_a Menu::MenuGetAnotherDigitOrTimeout
                  expect(menu_instance.status).to eq(:potential)
                  menu_instance << 2
                  expect(menu_instance.continue).to be_a Menu::MenuLimitReached
                  expect(menu_instance.continue).to be_a Menu::MenuResultDone
                  expect(menu_instance.status).to eq(:limited)
                  expect(menu_instance.result).to eq('242')
                end
              end

              context "when a validator is defined" do
                let(:menu_instance) do
                  Menu.new options do
                    validator { |buffer| buffer == "242" }
                  end
                end

                it "buffers until the validator returns true, then returns MenuValidatorTerminated and sets the status to :validator_terminated" do
                  menu_instance << 2
                  menu_instance << 4
                  expect(menu_instance.continue).to be_a Menu::MenuGetAnotherDigitOrTimeout
                  expect(menu_instance.status).to eq(:potential)
                  menu_instance << 2
                  expect(menu_instance.continue).to be_a Menu::MenuValidatorTerminated
                  expect(menu_instance.continue).to be_a Menu::MenuResultDone
                  expect(menu_instance.status).to eq(:validator_terminated)
                  expect(menu_instance.result).to eq('242')
                end
              end

              context "when a digit limit and validator is defined" do
                let(:menu_instance) do
                  Menu.new options.merge(:limit => 3) do
                    validator { |buffer| buffer == "242" }
                  end
                end

                it "applies the validator before checking the digit limit" do
                  menu_instance << 2
                  menu_instance << 4
                  menu_instance << 2
                  expect(menu_instance.continue).to be_a Menu::MenuValidatorTerminated
                  expect(menu_instance.continue).to be_a Menu::MenuResultDone
                  expect(menu_instance.status).to eq(:validator_terminated)
                  expect(menu_instance.result).to eq('242')
                end
              end
            end

          end#continue

          describe Menu::ClearableStringBuffer do
            subject { Menu::ClearableStringBuffer.new }

            it "adds a string to itself" do
              subject << 'b'
              subject << 'c'
              expect(subject).to eq('bc')
            end

            it "clears itself" do
              subject << 'a'
              subject.clear!
              expect(subject).to eq("")
            end
          end

      end # describe Menu
    end
  end
end
