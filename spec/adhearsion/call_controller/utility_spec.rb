# encoding: utf-8

require 'spec_helper'

module Adhearsion
  class CallController
    describe Utility do
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
          subject.grammar_digits(2).to_s.should be == grxml.to_s
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
          subject.grammar_accept('35').to_s.should be == grxml.to_s
        end

        it 'filters meaningless characters out' do
          subject.grammar_accept('3+5').to_s.should be == grxml.to_s
        end
      end # grammar_accept

      describe "#parse_dtmf" do
        context "with a single digit" do
          it "correctly returns the parsed input" do
            subject.parse_dtmf("dtmf-3").should be == '3'
          end

          it "correctly returns star as *" do
            subject.parse_dtmf("dtmf-star").should be == '*'
          end

          it "correctly returns * as *" do
            subject.parse_dtmf("*").should be == '*'
          end

          it "correctly returns pound as #" do
            subject.parse_dtmf("dtmf-pound").should be == '#'
          end

          it "correctly returns # as #" do
            subject.parse_dtmf("#").should be == '#'
          end

          it "correctly parses digits without the dtmf- prefix" do
            subject.parse_dtmf('1').should be == '1'
          end

          it "correctly returns nil when input is nil" do
            subject.parse_dtmf(nil).should be == nil
          end
        end

        context "with multiple digits separated by spaces" do
          it "returns the digits without space separation" do
            subject.parse_dtmf('1 dtmf-5 dtmf-star # 2').should be == '15*#2'
          end
        end
      end # describe #grammar_accept
    end
  end
end
