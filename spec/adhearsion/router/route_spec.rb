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
    end
  end
end
