require 'spec_helper'
require 'adhearsion/voip/asterisk/config_generators/queues.conf'

module QueuesConfigFileGeneratorTestHelper

  def reset_queues!
    @queues = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Queues.new
  end

  def generated_config_should_have_pair(pair)
    generated_config_has_pair(pair).should be true
  end

  def generated_config_has_pair(pair)
    queues.to_s.split("\n").grep(/=[^>]/).each do |line|
      key, value = line.strip.split('=')
      return true if pair == {key.to_sym => value}
    end
    false
  end
end

describe "The queues.conf config file generator" do

  include QueuesConfigFileGeneratorTestHelper

  attr_reader :queues
  before(:each) do
    reset_queues!
  end

  it 'should set autofill=yes by default' do
    generated_config_should_have_pair :autofill => 'yes'
  end

  it 'should have a [general] section' do
    queues.conf.should include "[general]\n"
  end

  it 'should yield a Queues object in its constructor' do
    Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Queues.new do |config|
      config.should be_a_kind_of Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Queues
    end
  end

  it 'should add the warning message to the to_s output' do
    queues.conf.should =~ /^\s*;.{10}/
  end

end

describe "The queues.conf config file queues's QueueDefinition" do

  include QueuesConfigFileGeneratorTestHelper

  attr_reader :queues
  before(:each) do
    reset_queues!
  end

  it 'should include [queue_name]' do
    name_of_queue = "leet_hax0rz"
    queues.queue(name_of_queue).to_s.should include "[#{name_of_queue}]"
  end

  it '#member should create a valid Agent "channel driver" to the member definition list' do
    sample_queue = queues.queue "sales" do |sales|
      sales.member 123
      sales.member "Jay"
      sales.member 'SIP/jay-desk-650'
      sales.member 'IAX2/12345@voipms/15554443333'
    end
    sample_queue.members.should == %w[Agent/123 Agent/Jay SIP/jay-desk-650 IAX2/12345@voipms/15554443333]
  end

  it 'should automatically enable the two AMI-related events' do
    @queues = queues.queue 'name'
    generated_config_should_have_pair :eventwhencalled   => 'vars'
    generated_config_should_have_pair :eventmemberstatus => 'yes'
  end

  it '#strategy should only allow the pre-defined settings' do
    [:ringall, :roundrobin, :leastrecent, :fewestcalls, :random, :rrmemory].each do |strategy|
      the_following_code {
        q = queues.queue 'foobar'
        q.strategy strategy
      }.should_not raise_error
    end

    the_following_code {
      queues.queue('qwerty').strategy :this_is_not_a_valid_strategy
    }.should raise_error ArgumentError

  end

  it '#sound_files raises an argument error when it sees an unrecognized key' do
    the_following_code {
      queues.queue 'foobar' do |foobar|
        foobar.sound_files \
          :you_are_next          => rand.to_s,
          :there_are             => rand.to_s,
          :calls_waiting         => rand.to_s,
          :hold_time             => rand.to_s,
          :minutes               => rand.to_s,
          :seconds               => rand.to_s,
          :thank_you             => rand.to_s,
          :less_than             => rand.to_s,
          :report_hold           => rand.to_s,
          :periodic_announcement => rand.to_s
      end
    }.should_not raise_error

    [:x_you_are_next, :x_there_are, :x_calls_waiting, :x_hold_time, :x_minutes,
     :x_seconds, :x_thank_you, :x_less_than, :x_report_hold, :x_periodic_announcement].each do |bad_key|
       the_following_code {
         queues.queue("foobar") do |foobar|
           foobar.sound_files bad_key => rand.to_s
         end
       }.should raise_error ArgumentError
    end

  end

end

describe "The private, helper methods in QueueDefinition" do

  include QueuesConfigFileGeneratorTestHelper

  attr_reader :queue
  before(:each) do
    reset_queues!
    @queue = @queues.queue "doesn't matter"
  end

  it '#boolean should convert a boolean into "yes" or "no"' do
    mock_of_properties = flexmock "mock of the properties instance variable of a QueueDefinition"
    mock_of_properties.should_receive(:[]=).once.with("icanhascheezburger", "yes")
    flexmock(queue).should_receive(:properties).and_return mock_of_properties
    queue.send(:boolean, "icanhascheezburger" => true)
  end

  it '#int should raise an argument error when its argument is not Numeric' do
    the_following_code {
      queue.send(:int, "eisley" => :i_break_things!)
    }.should raise_error ArgumentError
  end

  it '#int should coerce a String into a Numeric if possible' do
    mock_of_properties = flexmock "mock of the properties instance variable of a QueueDefinition"
    mock_of_properties.should_receive(:[]=).once.with("chimpanzee", 1337)
    flexmock(queue).should_receive(:properties).and_return mock_of_properties
    queue.send(:int, "chimpanzee" => "1337")
  end

  it '#string should add the argument directly to the properties' do
    mock_of_properties = flexmock "mock of the properties instance variable of a QueueDefinition"
    mock_of_properties.should_receive(:[]=).once.with("eins", "zwei")
    flexmock(queue).should_receive(:properties).and_return mock_of_properties
    queue.send(:string, "eins" => "zwei")
  end

  it '#one_of() should add its successful match to the properties attribute' do
    mock_properties = flexmock "mock of the properties instance variable of a QueueDefinition"
    mock_properties.should_receive(:[]=).once.with(:doesnt_matter, 5)
    flexmock(queue).should_receive(:properties).once.and_return mock_properties

    queue.send(:one_of, 1..100, :doesnt_matter => 5)
  end

  it "one_of() should convert booleans to yes/no" do
    mock_properties = flexmock "mock of the properties instance variable of a QueueDefinition"
    mock_properties.should_receive(:[]=).once.with(:doesnt_matter, 'yes')
    flexmock(queue).should_receive(:properties).once.and_return mock_properties
    queue.send(:one_of, [true, false, :strict], :doesnt_matter => true)

    mock_properties = flexmock "mock of the properties instance variable of a QueueDefinition"
    mock_properties.should_receive(:[]=).once.with(:doesnt_matter, :strict)
    flexmock(queue).should_receive(:properties).once.and_return mock_properties
    queue.send(:one_of, [true, false, :strict], :doesnt_matter => :strict)

    mock_properties = flexmock "mock of the properties instance variable of a QueueDefinition"
    mock_properties.should_receive(:[]=).once.with(:doesnt_matter, 'no')
    flexmock(queue).should_receive(:properties).once.and_return mock_properties
    queue.send(:one_of, [true, false, :strict], :doesnt_matter => false)
  end

  it '#one_of() should raise an ArgumentError if a value is not in the criteria' do
    the_following_code {
      queue.send(:one_of, [:jay, :thomas, :phillips], :sister => :jill)
    }.should raise_error ArgumentError
  end
end

describe 'The queues.conf config file generator when ran against a really big example' do

  include QueuesConfigFileGeneratorTestHelper

  attr_reader :queues, :default_config
  before(:each) do
    reset_queues!
    @default_config = default_config = <<-CONFIG
[general]
persistentmembers=yes
autofill=yes
monitor-type=MixMonitor

[markq]
musicclass=default
announce=queue-markq
strategy=ringall
servicelevel=60
context=qoutcon
timeout=15
retry=5
weight=0
wrapuptime=15
autofill=yes
autopause=yes
maxlen=0
setinterfacevar=yes
announce-frequency=90
periodic-announce-frequency=60
announce-holdtime=once
announce-round-seconds=10
queue-youarenext=queue-youarenext
queue-thereare=queue-thereare
queue-callswaiting=queue-callswaiting
queue-holdtime=queue-holdtime
queue-minutes=queue-minutes
queue-seconds=queue-seconds
queue-thankyou=queue-thankyou
queue-lessthan=queue-less-than
queue-reporthold=queue-reporthold
periodic-announce=queue-periodic-announce
monitor-format=gsm
monitor-type=MixMonitor
joinempty=yes
leavewhenempty=yes
eventwhencalled=vars
eventmemberstatus=yes
reportholdtime=no
ringinuse=no
memberdelay=0
timeoutrestart=no

member => Zap/1
member => Agent/007
CONFIG
  end

  it "a sample config with multiple queues" do

    generated = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Queues.new do |config|
      config.persistent_members true
      config.monitor_type :mix_monitor

      config.queue 'markq' do |markq|
        markq.music_class :default
        markq.play_on_connect 'queue-markq'
        markq.strategy :ringall
        markq.service_level 60
        markq.exit_to_context_on_digit_press 'qoutcon'
        markq.ring_timeout 15
        markq.retry_after_waiting 5
        markq.weight 0
        markq.wrapup_time 15
        markq.autopause true
        markq.maximum_length 0
        markq.queue_status_announce_frequency 90
        markq.announce_hold_time :once
        markq.announce_round_seconds 10
        markq.sound_files \
          :you_are_next  => "queue-youarenext",
          :there_are     => "queue-thereare",
          :calls_waiting => "queue-callswaiting",
          :hold_time     => "queue-holdtime",
          :minutes       => "queue-minutes",
          :seconds       => "queue-seconds",
          :thank_you     => "queue-thankyou",
          :less_than     => "queue-less-than",
          :report_hold   => "queue-reporthold"
        markq.periodically_announce "queue-periodic-announce"
        markq.monitor_format :gsm
        markq.monitor_type :mix_monitor
        markq.join_empty true
        markq.leave_when_empty true
        markq.report_hold_time false
        markq.ring_in_use false
        markq.delay_connection_by 0
        markq.timeout_restart false

        markq.member 'Zap/1'
        markq.member '007'
      end
    end

    cleaned_up_default_config = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::
      AsteriskConfigGenerator.create_sanitary_hash_from(default_config)

    cleaned_up_generated_config = generated.to_sanitary_hash

    cleaned_up_generated_config.should == cleaned_up_default_config
  end

end

describe "ConfigFileGeneratorTestHelper" do

  include QueuesConfigFileGeneratorTestHelper

  attr_reader :queues

  it "generated_config_has_pair() works properly" do
    @queues = flexmock "A fake queues with just one pair", :to_s => "foo=bar"
    generated_config_has_pair(:foo => "bar").should be true

    @queues = flexmock "A fake queues with just one pair", :to_s => "[general]\n\nqaz=qwerty\nagent => 1,2,3"
    generated_config_has_pair(:qaz => "qwerty").should be true
    generated_config_has_pair(:foo => "bar").should be false
  end

end
