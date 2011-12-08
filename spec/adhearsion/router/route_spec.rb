require 'spec_helper'

module Adhearsion
  class Router
    describe Route do
      describe 'a new route' do
        let(:name) { 'catchall' }
        let(:guards) do
          [
            {:to => /foobar/},
            [{:from => 'fred'}, {:from => 'paul'}]
          ]
        end

        describe "with a class target and guards" do
          let(:target) { Class.new }

          subject { Route.new name, target, *guards }

          its(:name)    { should == name }
          its(:target)  { should == target }
          its(:guards)  { should == guards }
        end

        describe "with a block target and guards" do
          let(:target) { Class.new }

          subject { Route.new(name, *guards) { :foo } }

          its(:name)    { should == name }
          its(:target)  { should be_a Proc }
          its(:guards)  { should == guards }
        end
      end

      describe "a guarded route" do
        subject { Route.new 'foobar', Class.new, *guards}

        def should_match_the_call
          subject.match?(call).should be true
        end

        def should_not_match_the_call
          subject.match?(call).should be false
        end

        describe "matching calls from fred to paul" do
          let :guards do
            [
              {:from => 'fred', :to => 'paul'}
            ]
          end

          context "with a call from fred to paul" do
            let(:call) { flexmock 'Adhearsion::Call', :from => 'fred', :to => 'paul' }
            it { should_match_the_call }
          end

          context "with a call from fred to frank" do
            let(:call) { flexmock 'Adhearsion::Call', :from => 'fred', :to => 'frank' }
            it { should_not_match_the_call }
          end

          context "with a call from frank to paul" do
            let(:call) { flexmock 'Adhearsion::Call', :from => 'frank', :to => 'paul' }
            it { should_not_match_the_call }
          end
        end
      end
    end
  end
end
