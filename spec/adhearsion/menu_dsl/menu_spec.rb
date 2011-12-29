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

            #it "should evaluate the block on the builder object" do
              #mock_menu_builder = flexmock(MenuBuilder.new)
              #flexmock(MenuBuilder).should_receive(:new).and_return(mock_menu_builder)
              #mock_menu_builder.should_receive(:match).once.with(1)
              #menu = Menu.new {match 1}
            #end
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
