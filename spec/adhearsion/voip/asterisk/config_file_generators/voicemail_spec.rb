require 'spec_helper'
require 'adhearsion/voip/asterisk/config_generators/voicemail.conf'

describe 'Basic requirements of the Voicemail config generator' do
  attr_reader :config
  before :each do
    @config = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Voicemail.new
  end

  it 'should have a [general] context' do
    config.to_sanitary_hash.has_key?('[general]').should be true
  end

  it 'should set the format to "wav" by default in the general section' do
    config.to_sanitary_hash['[general]'].should include 'format=wav'
  end

  it 'an exception should be raised if the context name is "general"' do
    the_following_code {
      config.context(:general) {|_|}
    }.should raise_error ArgumentError
  end

end

describe 'Defining recording-related settings of the Voicemail config file' do

  attr_reader :recordings
  before :each do
    @recordings = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Voicemail::RecordingDefinition.new
  end

  it 'the recordings setting setter' do
    Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Voicemail.new.recordings.should be_a_kind_of recordings.class
  end

  it 'recordings format should only allow a few options' do
    the_following_code {
      recordings.format :wav
      recordings.format :wav49
      recordings.format :gsm
    }.should_not raise_error

    the_following_code {
      recordings.format :lolcats
    }.should raise_error ArgumentError
  end

end

describe 'Defining email-related Voicemail settings' do

  attr_reader :email
  before :each do
    @email = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Voicemail::EmailDefinition.new
  end

  it 'the [] operator is overloaded to return conveniences for the body() and subject() methods' do
    variables = %{#{email[:name]} #{email[:mailbox]} #{email[:date]} #{email[:duration]} } +
                %{#{email[:message_number]} #{email[:caller_id]} #{email[:caller_id_number]} } +
                %{#{email[:caller_id_name]}}
    formatted = %{${VM_NAME} ${VM_MAILBOX} ${VM_DATE} ${VM_DUR} ${VM_MSGNUM} ${VM_CALLERID} ${VM_CIDNUM} ${VM_CIDNAME}}
    email.body variables
    email.subject variables
    email.properties[:emailbody].should == formatted
    email.properties[:emailsubject].should == formatted
  end

  it 'when defining a body, newlines should be escaped and carriage returns removed' do
    unescaped, escaped = "one\ntwo\n\r\r\nthree\n\n\n", 'one\ntwo\n\nthree\n\n\n'
    email.body unescaped
    email.properties[:emailbody].should == escaped
  end

  it 'the body must not be allowed to exceed 512 characters' do
    the_following_code {
      email.body "X" * 512
    }.should_not raise_error ArgumentError

    the_following_code {
      email.body "X" * 513
    }.should raise_error ArgumentError

    the_following_code {
      email.body "X" * 1000
    }.should raise_error ArgumentError
  end

  it 'should store away the email command properly' do
    mail_command = "/usr/sbin/sendmail -f alice@wonderland.com -t"
    email.command mail_command
    email.properties[:mailcmd].should == mail_command
  end

end

describe 'A mailbox definition' do
  attr_reader :mailbox
  before :each do
    @mailbox = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Voicemail::ContextDefinition::MailboxDefinition.new("123")
  end

  it 'setting the name should be reflected in the to_hash form of the definition' do
    mailbox.name "Foobar"
    mailbox.to_hash[:name].should == "Foobar"
  end

  it 'setting the pin_number should be reflected in the to_hash form of the definition' do
    mailbox.pin_number 555
    mailbox.to_hash[:pin_number].should == 555
  end

  it 'the mailbox number should be available in the mailbox_number getter' do
    Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Voicemail::ContextDefinition::MailboxDefinition.new '123'
    mailbox.mailbox_number.should == '123'
  end

  it 'an ArgumentError should be raised if the mailbox_number is not numeric' do
    the_following_code {
      Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Voicemail::ContextDefinition::MailboxDefinition.new("this is not numeric")
    }.should raise_error ArgumentError
  end

  it 'an ArgumentError should be raised if the pin_number is not numeric' do
    the_following_code {
      mailbox.pin_number "this is not numeric"
    }.should raise_error ArgumentError
  end

  it "the string representation should be valid" do
    expected = "123 => 1337,Jay Phillips,ahn@adhearsion.com"
    mailbox.pin_number 1337
    mailbox.name "Jay Phillips"
    mailbox.email "ahn@adhearsion.com"
    mailbox.to_s.should == expected
  end

  it 'should not add a trailing comma when the email is left out' do
    mailbox.pin_number 1337
    mailbox.name "Jay Phillips"
    mailbox.to_s.ends_with?(',').should be false
  end

  it 'should not add a trailing comma when the email and name is left out' do
    mailbox.pin_number 1337
    mailbox.to_s.ends_with?(',').should be false
  end

end

describe "A Voicemail context definition" do

  it "should ultimately add a [] context definition to the string output" do
    voicemail = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Voicemail.new
    voicemail.context "monkeys" do |config|
      config.should be_a_kind_of voicemail.class::ContextDefinition
      config.mailbox 1234 do |mailbox|
        mailbox.pin_number 3333
        mailbox.email "alice@wonderland.com"
        mailbox.name "Alice Little"
      end
    end
    voicemail.to_sanitary_hash.has_key?('[monkeys]').should be true
  end

  it 'should raise a LocalJumpError if no block is given' do
    the_following_code {
      Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Voicemail.new.context('lols')
    }.should raise_error LocalJumpError
  end

  it 'its string representation should begin with a context declaration' do
    vm = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Voicemail.new
    vm.context("jay") {|_|}.to_s.starts_with?("[jay]").should be true
  end

end

describe 'Defining Voicemail contexts with mailbox definitions' do

end

describe 'An expansive example of the Voicemail config generator' do

  before :each do
    @employees = [
      {:name => "Tango",  :pin_number => 7777, :mailbox_number => 10},
      {:name => "Echo",   :pin_number => 7777, :mailbox_number => 20},
      {:name => "Sierra", :pin_number => 7777, :mailbox_number => 30},
      {:name => "Tango2", :pin_number => 7777, :mailbox_number => 40}
    ].map { |hash| OpenStruct.new(hash) }

    @groups = [
      {:name => "Brand New Cadillac", :pin_number => 1111, :mailbox_number => 1},
      {:name => "Jimmy Jazz",         :pin_number => 2222, :mailbox_number => 2},
      {:name => "Death or Glory",     :pin_number => 3333, :mailbox_number => 3},
      {:name => "Rudie Can't Fail",   :pin_number => 4444, :mailbox_number => 4},
      {:name => "Spanish Bombs",      :pin_number => 5555, :mailbox_number => 5}
    ].map { |hash| OpenStruct.new(hash) }
  end

  it 'a huge, brittle integration test' do
    vm = Adhearsion::VoIP::Asterisk::ConfigFileGenerators::Voicemail.new do |voicemail|
      voicemail.context :default do |context|
        context.mailbox 123 do |mailbox|
          mailbox.name "Administrator"
          mailbox.email "jabberwocky@wonderland.com"
          mailbox.pin_number 9876
        end
      end

      voicemail.context :employees do |context|
        @employees.each do |employee|
          context.mailbox employee.mailbox_number do |mailbox|
            mailbox.pin_number 1337
            mailbox.name employee.name
          end
        end
      end

      voicemail.context :groups do |context|
        @groups.each do |group|
          context.mailbox group.mailbox_number do |mailbox|
            mailbox.pin_number 1337
            mailbox.name group.name
            mailbox.email "foo@qaz.org"
          end
        end
      end

      voicemail.execute_on_pin_change "/path/to/my/changer_script.rb"
      ############################################################################
      ############################################################################

      signature = "Your Friendly Phone System"

      # execute_after_email "netcat 192.168.1.2 12345"
      # greeting_maximum 1.minute
      # time_jumped_with_skip_key 3.seconds # milliseconds!
      # logging_in do |config|
      #   config.maximum_attempts 3
      # end

      voicemail.recordings do |config|
        config.format :wav # ONCE YOU PICK A FORMAT, NEVER CHANGE IT UNLESS YOU KNOW THE CONSEQUENCES!
        config.allowed_length 3.seconds..5.minutes
        config.maximum_silence 10.seconds
        # config.silence_threshold 128 # wtf?
      end

      voicemail.emails do |config|
        config.from :name => signature, :email => "noreply@adhearsion.com"
        config.attach_recordings true
        config.command '/usr/sbin/sendmail -f alice@wonderland.com -t'
        config.subject "New voicemail for #{config[:name]}"
        config.body <<-BODY.unindent
          Dear #{config[:name]}:

          The caller #{config[:caller_id]} left you a #{config[:duration]} long voicemail
          (number #{config[:message_number]}) on #{config[:date]} in mailbox #{config[:mailbox]}.

          #{ "The recording is attached to this email.\n" if config.attach_recordings? }
          - #{signature}
        BODY
      end
    end
    internalized = vm.to_sanitary_hash
    internalized.size.should == 5 # general, zonemessages, default, employees, groups

    target_config = <<-CONFIG
[general]
attach=yes
emailbody=Dear ${VM_NAME}:\\nThe caller ${VM_CALLERID} left you a ${VM_DUR} long voicemail\\n(number ${VM_MSGNUM}) on ${VM_DATE} in mailbox ${VM_MAILBOX}.\\nThe recording is attached to this email.\\n- Your Friendly Phone System\\n
emailsubject=New voicemail for ${VM_NAME}
externpass=/path/to/my/changer_script.rb
format=wav
fromstring=Your Friendly Phone System
mailcmd=/usr/sbin/sendmail -f alice@wonderland.com -t
serveremail=noreply@adhearsion.com

[zonemessages]
eastern=America/New_York|'vm-received' Q 'digits/at' IMp
central=America/Chicago|'vm-received' Q 'digits/at' IMp
central24=America/Chicago|'vm-received' q 'digits/at' H N 'hours'
military=Zulu|'vm-received' q 'digits/at' H N 'hours' 'phonetic/z_p'
european=Europe/Copenhagen|'vm-received' a d b 'digits/at' HM
[default]
123 => 9876,Administrator,jabberwocky@wonderland.com

[employees]
10 => 1337,Tango
20 => 1337,Echo
30 => 1337,Sierra
40 => 1337,Tango2

[groups]
1 => 1337,Brand New Cadillac,foo@qaz.org
2 => 1337,Jimmy Jazz,foo@qaz.org
3 => 1337,Death or Glory,foo@qaz.org
4 => 1337,Rudie Can't Fail,foo@qaz.org
5 => 1337,Spanish Bombs,foo@qaz.org
    CONFIG
    vm.to_s.split("\n").grep(/^$|^[^;]/).join("\n").strip.should == target_config.strip

  end
end
