require 'spec_helper'

module Adhearsion
  module Punchblock
    module Commands
      describe Dial do
        include PunchblockCommandTestHelpers

        describe "#dial" do
          describe "without a block" do
            it "blocks the original dialplan until the new call hangs up"

            it "joins the new call to the existing one"
          end

        	describe "with a block" do
            it "uses the block as the dialplan for the new call"

            it "joins the new call to the existing call once the block returns"

            it "does not try to join the calls if the new call is hungup when the block returns"
          end
        end
      end
    end
  end
end
