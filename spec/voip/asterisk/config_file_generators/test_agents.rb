require File.join(File.dirname(__FILE__), *%w[.. .. .. test_helper])
require 'adhearsion/voip/asterisk/config_generators/agents.conf'

context "The agents.conf config file generator" do
  test "truth" do
    true.should.be true
  end
end