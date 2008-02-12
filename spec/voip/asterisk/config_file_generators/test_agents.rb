require File.join(File.dirname(__FILE__), *%w[.. .. .. test_helper])
require 'adhearsion/voip/asterisk/config_generators/agents.conf'

context "The agents.conf config file generator" do
  
  include ConfigFileGeneratorTestHelper
  
  attr_reader :generator
  before:each do
    reset_generator!
  end
  test "The agent() method should enqueue a Hash into Agents#agent_definitions" do
    generator.agent 1337, :password => 9876, :name => "Jay Phillips"
    generator.agent_definitions.size.should.be 1
    generator.agent_definitions.first.should == {:id => 1337, :password => 9876, :name => "Jay Phillips"}
  end
  
  test "The to_s() method should always create a general section" do
    generator.to_s.should =~ /^\[general\]/
  end
  
  test "The agent() method should generate a proper String" do
    generator.agent 123, :name => "Otto Normalverbraucher", :password => "007"
    generator.agent 889, :name => "John Doe", :password => "998"
    
    generator.to_s.grep(/^agent =>/).map(&:strip).should == [
      "agent => 123,007,Otto Normalverbraucher",
      "agent => 889,998,John Doe"
    ]
  end
  
  test "The persistent_agents() method should generate a persistentagents yes/no pair" do
    generator.persistent_agents true
    generated_config_has_pair(:persistentagents => "yes").should.be true
    
    reset_generator!
    
    generator.persistent_agents false
    generated_config_has_pair(:persistentagents => "no").should.be true
  end
  
  test "The persistent_agents() method should be in the [general] section" do
    generator.persistent_agents true
    generator.general_section.should == {:persistentagents => "yes"}
    
  end
  
  test "max_login_tries() should generate a 'maxlogintries' numerical pair" do
    generator.max_login_tries 50
    generated_config_has_pair(:maxlogintries => "50").should.be true
  end
  
  test "max_login_tries() should be in the agents section" do
    generator.max_login_tries 0
    generator.agent_section.should == {:maxlogintries => 0}
  end
  
  test "log_off_after_duration should generate autologoff" do
    generator.log_off_after_duration 15.seconds
    generated_config_has_pair(:autologoff => "15").should.be true
  end
  
  test "log_off_if_unavailable should add autologoffunavail to the agents section" do
    generator.log_off_if_unavailable false
    generator.agent_section.should == {:autologoffunavail => "no"}
  end
  
  test "require_hash_to_acknowledge() should generate a 'ackcall' yes/no pair" do
    generator.require_hash_to_acknowledge false
    generator.agent_section.should == {:ackcall => "no"}
  end
  
  test "allow_star_to_hangup should generate a 'endcall' yes/no pair" do
    generator.allow_star_to_hangup false
    generator.agent_section.should == {:endcall => "no"}
  end
  
  test "time_between_calls should convert its argument to milliseconds" do
    generator.time_between_calls 1.hour
    generator.agent_section.should == {:wrapuptime => 1.hour * 1_000}
  end
  
  test "hold_music_class should convert its argument to a String" do
    generator.hold_music_class :podcast
    generator.agent_section_special.should == {:musiconhold => "podcast"}
  end
  
  test "play_on_agent_goodbye should generate 'agentgoodbye'" do
    generator.play_on_agent_goodbye "tt-monkeys"
    generator.agent_section_special.should == {:agentgoodbye => "tt-monkeys"}
  end
  
  test "change_cdr_source should generate updatecdr" do
    generator.change_cdr_source false
    generator.agent_section.should == {:updatecdr => "no"}
  end
  
  test "play_for_waiting_keep_alive" do
    generator.play_for_waiting_keep_alive "tt-weasels"
    generator.agent_section.should == {:custom_beep => "tt-weasels"}
  end
  
  test "save_recordings_in should generate 'savecallsin'" do
    generator.save_recordings_in "/second/star/on/the/right"
    generator.agent_section.should == {:savecallsin => "/second/star/on/the/right"}
  end
  
  test "recording_prefix should generate 'urlprefix'" do
    generator.recording_prefix "ohai"
    generator.agent_section.should == {:urlprefix => "ohai"}
  end
  
  test "recording_format should only allow a few symbols as an argument" do
    the_following_code {
      generator.recording_format :wav
      generator.agent_section.should == {:recordformat => :wav}
    }.should.not.raise
    
    reset_generator!
    
    the_following_code {
      generator.recording_format :wav49
      generator.agent_section.should == {:recordformat => :wav49}
    }.should.not.raise
    
    reset_generator!
    
    the_following_code {
      generator.recording_format :gsm
      generator.agent_section.should == {:recordformat => :gsm}
    }.should.not.raise
    
    reset_generator!
    
    the_following_code {
      generator.recording_format :mp3
      generator.agent_section.should == {:recordformat => :mp3}
    }.should.raise ArgumentError
    
  end
  
  test "record_agent_calls should generate a 'recordagentcalls' yes/no pair" do
    generator.record_agent_calls false
    generator.agent_section.should == {:recordagentcalls => 'no'}
  end
  
  test "allow_multiple_logins_per_extension should generate 'multiplelogin' in [general]" do
    generator.allow_multiple_logins_per_extension true
    generator.general_section.should == {:multiplelogin => 'yes'}
  end
  
end

context "The default agents.conf config file converted to this syntax" do
  
  include ConfigFileGeneratorTestHelper
  
  attr_reader :default_config, :generator
  before:each do
    reset_generator!
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
    generator.persistent_agents true
    generator.max_login_tries 5
    generator.log_off_after_duration 15
    generator.require_hash_to_acknowledge false
    generator.allow_star_to_hangup true
    generator.time_between_calls 5
    generator.hold_music_class :default
    generator.play_on_agent_goodbye "goodbye_file"
    generator.change_cdr_source false
    generator.groups 1,2
    generator.record_agent_calls true
    generator.recording_format :gsm
    generator.recording_prefix "http://localhost/calls/"
    generator.save_recordings_in "/var/calls"
    generator.play_for_waiting_keep_alive "beep"

    generator.agent 1001, :password => 4321, :name => "Mark Spencer"
    generator.agent 1002, :password => 4321, :name => "Will Meadows"

    generated_config_lines = generator.to_s.split(/\n+/).map(&:strip)
    default_config_lines = default_config.split(/\n+/).map(&:strip)

    (generated_config_lines - default_config_lines).should.be.empty
  end
  
end


context "ConfigFileGeneratorTestHelper" do
  
  include ConfigFileGeneratorTestHelper
  
  attr_reader :generator
  
  test "generated_config_has_pair() works properly" do
    @generator = flexmock "A fake generator with just one pair", :to_s => "foo=bar"
    generated_config_has_pair(:foo => "bar").should.be true
    
    @generator = flexmock "A fake generator with just one pair", :to_s => "[general]\n\nqaz=qwerty\nagent => 1,2,3"
    generated_config_has_pair(:qaz => "qwerty").should.be true
    generated_config_has_pair(:foo => "bar").should.be false
  end
end

BEGIN {
module ConfigFileGeneratorTestHelper
  
  def reset_generator!
    @generator = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Agents.new
  end
  
  def generated_config_has_pair(pair)
    generator.to_s.grep(/=[^>]/).each do |line|
      key, value = line.strip.split('=')
      return true if pair == {key.to_sym => value}
    end
    false
  end
end
}