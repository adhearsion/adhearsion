# encoding: utf-8

require 'spec_helper'

describe Adhearsion::Rayo::CommandNode do
  let(:args) { [] }
  subject(:command) do
    Class.new(described_class) { register 'foo'}.new(*args)
  end

  describe '#state_name' do
    subject { super().state_name }
    it { is_expected.to eq(:new) }
  end

  describe '#request_id' do
    subject { super().request_id }
    it { is_expected.to eq(@uuid) }
  end

  describe "#new" do
    describe "with a call/component ID" do
      let(:call_id)       { 'abc123' }
      let(:component_id)  { 'abc123' }
      let(:args)          { [{:target_call_id => call_id, :component_id => component_id}] }

      describe '#target_call_id' do
        subject { super().target_call_id }
        it { is_expected.to eq(call_id) }
      end

      describe '#component_id' do
        subject { super().component_id }
        it { is_expected.to eq(component_id) }
      end
    end
  end

  describe "#request!" do
    before { command.request! }

    describe '#state_name' do
      subject { command.state_name }
      it { is_expected.to eq(:requested) }
    end

    it "should raise a StateMachine::InvalidTransition when received a second time" do
      expect { command.request! }.to raise_error(StateMachine::InvalidTransition)
    end
  end

  describe "#execute!" do
    describe "without sending" do
      it "should raise a StateMachine::InvalidTransition" do
        expect { subject.execute! }.to raise_error(StateMachine::InvalidTransition)
      end
    end

    describe "after sending" do
      before do
        command.request!
        command.execute!
      end

      describe '#state_name' do
        subject { super().state_name }
        it { is_expected.to eq(:executing) }
      end
    end
  end

  describe "#complete!" do
    before do
      command.request!
      command.execute!
      command.complete!
    end

    describe '#state_name' do
      subject { super().state_name }
      it { is_expected.to eq(:complete) }
    end

    it "should raise a StateMachine::InvalidTransition when received a second time" do
      expect { subject.complete! }.to raise_error(StateMachine::InvalidTransition)
    end
  end # #complete!

  describe "#response=" do
    it "should set the command to executing status" do
      expect(subject).to receive(:execute!).once
      subject.response = :foo
    end

    it "should be a no-op if the response has already been set" do
      expect(subject).to receive(:execute!).once
      subject.response = :foo
      expect { subject.response = :bar }.not_to raise_error
    end
  end
end
