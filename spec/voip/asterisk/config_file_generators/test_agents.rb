require File.join(File.dirname(__FILE__), *%w[.. .. .. test_helper])
require 'adhearsion/voip/asterisk/config_generators/agents.conf'

context "The agents.conf config file agents" do
  
  include AgentsConfigFileGeneratorTestHelper
  
  attr_reader :agents
  before:each do
    reset_agents!
  end
  test "The agent() method should enqueue a Hash into Agents#agent_definitions" do
    agents.agent 1337, :password => 9876, :name => "Jay Phillips"
    agents.agent_definitions.size.should.be 1
    agents.agent_definitions.first.should == {:id => 1337, :password => 9876, :name => "Jay Phillips"}
  end
  
  test "The conf() method should always create a general section" do
    agents.conf.should =~ /^\[general\]/
  end
  
  test "The agent() method should generate a proper String" do
    agents.agent 123, :name => "Otto Normalverbraucher", :password => "007"
    agents.agent 889, :name => "John Doe", :password => "998"
    
    agents.conf.grep(/^agent =>/).map(&:strip).should == [
      "agent => 123,007,Otto Normalverbraucher",
      "agent => 889,998,John Doe"
    ]
  end
  
  test "The persistent_agents() method should generate a persistentagents yes/no pair" do
    agents.persistent_agents true
    generated_config_has_pair(:persistentagents => "yes").should.be true
    
    reset_agents!
    
    agents.persistent_agents false
    generated_config_has_pair(:persistentagents => "no").should.be true
  end
  
  test "The persistent_agents() method should be in the [general] section" do
    agents.persistent_agents true
    agents.general_section.should == {:persistentagents => "yes"}
    
  end
  
  test "max_login_tries() should generate a 'maxlogintries' numerical pair" do
    agents.max_login_tries 50
    generated_config_has_pair(:maxlogintries => "50").should.be true
  end
  
  test "max_login_tries() should be in the agents section" do
    agents.max_login_tries 0
    agents.agent_section.should == {:maxlogintries => 0}
  end
  
  test "log_off_after_duration should generate autologoff" do
    agents.log_off_after_duration 15.seconds
    generated_config_has_pair(:autologoff => "15").should.be true
  end
  
  test "log_off_if_unavailable should add autologoffunavail to the agents section" do
    agents.log_off_if_unavailable false
    agents.agent_section.should == {:autologoffunavail => "no"}
  end
  
  test "require_hash_to_acknowledge() should generate a 'ackcall' yes/no pair" do
    agents.require_hash_to_acknowledge false
    agents.agent_section.should == {:ackcall => "no"}
  end
  
  test "allow_star_to_hangup should generate a 'endcall' yes/no pair" do
    agents.allow_star_to_hangup false
    agents.agent_section.should == {:endcall => "no"}
  end
  
  test "time_between_calls should convert its argument to milliseconds" do
    agents.time_between_calls 1.hour
    agents.agent_section.should == {:wrapuptime => 1.hour * 1_000}
  end
  
  test "hold_music_class should convert its argument to a String" do
    agents.hold_music_class :podcast
    agents.agent_section_special.should == {:musiconhold => "podcast"}
  end
  
  test "play_on_agent_goodbye should generate 'agentgoodbye'" do
    agents.play_on_agent_goodbye "tt-monkeys"
    agents.agent_section_special.should == {:agentgoodbye => "tt-monkeys"}
  end
  
  test "change_cdr_source should generate updatecdr" do
    agents.change_cdr_source false
    agents.agent_section.should == {:updatecdr => "no"}
  end
  
  test "play_for_waiting_keep_alive" do
    agents.play_for_waiting_keep_alive "tt-weasels"
    agents.agent_section.should == {:custom_beep => "tt-weasels"}
  end
  
  test "save_recordings_in should generate 'savecallsin'" do
    agents.save_recordings_in "/second/star/on/the/right"
    agents.agent_section.should == {:savecallsin => "/second/star/on/the/right"}
  end
  
  test "recording_prefix should generate 'urlprefix'" do
    agents.recording_prefix "ohai"
    agents.agent_section.should == {:urlprefix => "ohai"}
  end
  
  test "recording_format should only allow a few symbols as an argument" do
    the_following_code {
      agents.recording_format :wav
      agents.agent_section.should == {:recordformat => :wav}
    }.should.not.raise
    
    reset_agents!
    
    the_following_code {
      agents.recording_format :wav49
      agents.agent_section.should == {:recordformat => :wav49}
    }.should.not.raise
    
    reset_agents!
    
    the_following_code {
      agents.recording_format :gsm
      agents.agent_section.should == {:recordformat => :gsm}
    }.should.not.raise
    
    reset_agents!
    
    the_following_code {
      agents.recording_format :mp3
      agents.agent_section.should == {:recordformat => :mp3}
    }.should.raise ArgumentError
    
  end
  
  test "record_agent_calls should generate a 'recordagentcalls' yes/no pair" do
    agents.record_agent_calls false
    agents.agent_section.should == {:recordagentcalls => 'no'}
  end
  
  test "allow_multiple_logins_per_extension should generate 'multiplelogin' in [general]" do
    agents.allow_multiple_logins_per_extension true
    agents.general_section.should == {:multiplelogin => 'yes'}
  end
  
end

context "The default agents.conf config file converted to this syntax" do
  
  include AgentsConfigFileGeneratorTestHelper
  
  attr_reader :default_config, :agents
  before:each do
    reset_agents!
    @default_config = <<-CONFIG
[general]
persistentagents=yes

[agents]
maxlogintries=5
autologoff=15
ackcall=no
endcall=yes
wrapuptime=5000
musiconhold => default
agentgoodbye => goodbye_file
updatecdr=no
group=1,2
recordagentcalls=yes
recordformat=gsm
urlprefix=http://localhost/calls/
savecallsin=/var/calls
custom_beep=beep

agent => 1001,4321,Mark Spencer
agent => 1002,4321,Will Meadows
    CONFIG
  end
  
  test "they're basically the same" do
    agents.persistent_agents true
    agents.max_login_tries 5
    agents.log_off_after_duration 15
    agents.require_hash_to_acknowledge false
    agents.allow_star_to_hangup true
    agents.time_between_calls 5
    agents.hold_music_class :default
    agents.play_on_agent_goodbye "goodbye_file"
    agents.change_cdr_source false
    agents.groups 1,2
    agents.record_agent_calls true
    agents.recording_format :gsm
    agents.recording_prefix "http://localhost/calls/"
    agents.save_recordings_in "/var/calls"
    agents.play_for_waiting_keep_alive "beep"

    agents.agent 1001, :password => 4321, :name => "Mark Spencer"
    agents.agent 1002, :password => 4321, :name => "Will Meadows"

    cleaned_up_default_config = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::
      AsteriskConfigGenerator.create_sanitary_hash_from(default_config)
    
    cleaned_up_generated_config = agents.to_sanitary_hash
    
    cleaned_up_generated_config.should == cleaned_up_default_config
  end
  
end


context "AgentsConfigFileGeneratorTestHelper" do
  
  include AgentsConfigFileGeneratorTestHelper
  
  attr_reader :agents
  
  test "generated_config_has_pair() works properly" do
    @agents = flexmock "A fake agents with just one pair", :conf => "foo=bar"
    generated_config_has_pair(:foo => "bar").should.be true
    
    @agents = flexmock "A fake agents with just one pair", :conf => "[general]\n\nqaz=qwerty\nagent => 1,2,3"
    generated_config_has_pair(:qaz => "qwerty").should.be true
    generated_config_has_pair(:foo => "bar").should.be false
  end
end

BEGIN {
module AgentsConfigFileGeneratorTestHelper
  
  def reset_agents!
    @agents = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Agents.new
  end
  
  def generated_config_has_pair(pair)
    agents.conf.grep(/=[^>]/).each do |line|
      key, value = line.strip.split('=')
      return true if pair == {key.to_sym => value}
    end
    false
  end
  
end
}