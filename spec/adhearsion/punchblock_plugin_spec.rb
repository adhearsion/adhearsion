require 'spec_helper'

module Adhearsion
  describe PunchblockPlugin do
    it "should make the client accessible from the Initializer" do
      PunchblockPlugin::Initializer.client = :foo
      PunchblockPlugin.client.should be :foo
      PunchblockPlugin::Initializer.client = nil
    end
  end
end
