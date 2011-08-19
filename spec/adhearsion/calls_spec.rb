require 'spec_helper'

module Adhearsion
  describe Calls do
    describe "Active Calls" do
      let(:typical_call) { Adhearsion::Call.new mock_offer }

      after do
        Adhearsion.active_calls.clear!
      end

      it 'can add a call to the active calls list' do
        Adhearsion.active_calls.any?.should == false
        Adhearsion.active_calls << typical_call
        Adhearsion.active_calls.size.should == 1
      end

      it 'Can find active call by unique ID' do
        Adhearsion.active_calls << typical_call
        Adhearsion.active_calls.find(typical_call.id).should_not == nil
      end
    end

    it 'the #<< method should add a Call to the Hash with its id' do
      id = rand
      call = Adhearsion::Call.new mock_offer(id)
      subject << call
      hash = subject.instance_variable_get("@calls")
      hash.empty?.should_not == true
      hash[id].should be call
    end

    it '#size should return the size of the Hash' do
      subject.size.should == 0
      subject << Adhearsion::Call.new(mock_offer)
      subject.size.should == 1
    end

    it '#remove_inactive_call should delete the call in the Hash' do
      number_of_calls = 10
      calls = Array.new(number_of_calls) { Adhearsion::Call.new mock_offer }
      calls.each { |call| subject << call }

      deleted_call = calls[number_of_calls / 2]
      subject.remove_inactive_call deleted_call
      subject.size.should == number_of_calls - 1
    end

    it '#find should pull the Call from the Hash using the id' do
      id = rand
      call_database = flexmock "a mock Hash in which calls are stored"
      call_database.should_receive(:[]).once.with(id)
      flexmock(subject).should_receive(:calls).once.and_return(call_database)
      subject.find id
    end

    it "finding calls by a tag" do
      Adhearsion.active_calls.clear!

      calls = Array.new(5) { Adhearsion::Call.new mock_offer }
      calls.each { |call| subject << call }

      tagged_call = calls.last
      tagged_call.tag :moderator

      subject.with_tag(:moderator).should == [tagged_call]
    end
  end
end
