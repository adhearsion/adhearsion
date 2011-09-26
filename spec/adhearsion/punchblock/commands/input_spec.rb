require 'spec_helper'

module Adhearsion
  module Punchblock
    module Commands
      describe Input do
        include PunchblockCommandTestHelpers

        describe "grammar_digits" do 
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

        end#describe
      end#describe
    end
  end
end
