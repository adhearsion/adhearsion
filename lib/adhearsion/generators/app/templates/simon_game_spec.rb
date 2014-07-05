# encoding: utf-8

require 'spec_helper'
require 'call_controllers/simon_game'

describe SimonGame do

  let(:example_response)  { OpenStruct.new(:response => "5")     }
  let(:example_number)    { "5"                                  }
  let(:long_response)     { OpenStruct.new(:response => "55555") }
  let(:long_number)       { "55555"                              }

  let(:mock_call) { double 'Call' }
  subject { SimonGame.new(mock_call) }

  describe "#random_number" do

    before { allow(subject).to receive(:rand).and_return(example_number) }

    it "generates a random number" do
      expect(subject.random_number).to eq example_number
    end
  end

  describe "#update_number" do

    before { subject.number = "123" }
    before { allow(subject).to receive(:random_number).and_return "4" }

    it "adds a digit to the end of the number" do
      subject.update_number
      expect(subject.number).to eq "1234"
    end
  end

  describe "#collect_attempt" do

    context "when the @number is 1 digit long" do

      before { subject.number = "3" }

      it "asks for a 1 digits number" do
        expect(subject).to receive(:ask).with("3", :limit => 1).and_return(example_response)
        subject.collect_attempt
      end
    end

    context "when the @number is 5 digits long" do

      before { subject.number = long_number }

      it "asks for a 5 digits number" do
        expect(subject).to receive(:ask).with(long_number, :limit => 5).and_return(long_response)
        subject.collect_attempt
      end
    end

    context "sets @attempt" do

      before { subject.number = "12345" }

      it "based on the user's response" do
        expect(subject).to receive(:ask).with("12345", :limit => 5).and_return(long_response)
        subject.collect_attempt
        expect(subject.attempt).to eq long_number
      end
    end
  end

  describe "#attempt_correct?" do

    before { subject.number = "7" }

    context "with a good attempt" do

      before { subject.attempt = "7" }

      it "returns true" do
        expect(subject.attempt_correct?).to be_truthy
      end
    end

    context "with a bad attempt" do

      before { subject.attempt = "9" }

      it "returns true" do
        expect(subject.attempt_correct?).to be_falsey
      end
    end
  end

  describe "#verify_attempt" do
    context "when the user is a good guesser" do

      before { allow(subject).to receive(:attempt_correct?).and_return true }

      it "congradulates them" do
        expect(subject).to receive(:speak).with('good')
        subject.verify_attempt
      end
    end

    context "when the user guesses wrong" do

      before { subject.number  = "12345" }
      before { subject.attempt = "12346" }

      it "congradulates them" do
        expect(subject).to receive(:speak).with('4 times wrong, try again smarty')
        subject.verify_attempt
      end
    end
  end

  describe "#reset" do

    before { subject.reset }

    it "sets @number" do
      expect(subject.number).to eq ''
    end

    it "sets @attempt" do
      expect(subject.attempt).to eq ''
    end
  end

  describe "#run" do
    it "loops the loop" do
      expect(subject).to receive :answer
      expect(subject).to receive :reset

      expect(subject).to receive :update_number
      expect(subject).to receive :collect_attempt
      expect(subject).to receive(:verify_attempt).and_throw :rspec_loop_stop

      catch :rspec_loop_stop do
        subject.run
      end
    end
  end
end
