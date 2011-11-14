require 'spec_helper'

describe Adhearsion::Configuration do

  context "when initializing the config instance" do
    subject do 
      Adhearsion::Configuration.new
    end

    its(:automatically_accept_incoming_calls) { should == true}

    its(:end_call_on_hangup) { should == true }

    its(:end_call_on_error) { should == true }    

    its(:asterisk_enabled?) { should == true }

    its(:asterisk) { should be_kind_of OpenStruct }

    its(:database_enabled?) { should == false }

    its(:ldap_enabled?) { should == false }

    it "should not enable AMI by default" do
      subject.asterisk.ami_enabled?.should == false
    end

    it "should assign propertly the default AMI values" do
      subject.asterisk.default_ami.port.should == 5038
      subject.asterisk.default_ami.events.should == false
      subject.asterisk.default_ami.host.should == "localhost"
      subject.asterisk.default_ami.auto_reconnect.should == true
    end

    its(:drb_enabled?) { should == false }

    its(:xmpp_enabled?) { should == false }
  end

  context "when accessing asterisk configuration" do
    subject do 
      Adhearsion::Configuration.new.asterisk
    end

    it "sets default listening port" do
      subject.listening_port.should == 4573
    end

    it "sets default listening host" do
      subject.listening_host.should == "localhost"
    end

    it "sets default delimiter" do
      subject.argument_delimiter.should == "|"
    end
  end

  context 'Logging configuration' do
    subject do 
      Adhearsion::Configuration.new
    end

    before do
      Adhearsion::Logging.reset
      Adhearsion::Logging.start
    end

    it 'the logging level should translate from symbols into Logging constants' do
      Adhearsion::Logging.logging_level.should_not be Adhearsion::Logging::WARN
      subject.logging :level => :warn
      Adhearsion::Logging.logging_level.should be Adhearsion::Logging::WARN
    end

    it 'outputters should be settable' do
      Adhearsion::Logging.outputters.length.should eql(1)
      subject.logging :outputters => ::Logging.appenders.stdout
      Adhearsion::Logging.outputters.should == [::Logging.appenders.stdout]
    end

    it 'formatter should be settable' do
      Adhearsion::Logging.formatter.class.should == ::Logging::Layouts::Basic
      subject.logging :formatter => ::Logging::Layouts.pattern({:pattern => '[%d] %-5l %c: %m\n'})
      Adhearsion::Logging.formatter.class.should == ::Logging::Layouts.pattern
    end

    it 'a global formatter should be settable' do
      Adhearsion::Logging.formatter.class.should == ::Logging::Layouts::Basic
      subject.logging :formatter => ::Logging::Layouts.pattern({:pattern => '[%d] %-5l %c: %m\n'})
      Adhearsion::Logging.formatter.class.should == ::Logging::Layouts.pattern
    end
  end

  context "AMI configuration defaults" do
    subject do 
      Adhearsion::Configuration.new.asterisk.default_ami
    end

    it "ami configuration sets default port" do
      subject.port.should == 5038
    end

    it "ami allows you to configure a username and a password, both of which default to nil" do
      subject.username.should be_nil
      subject.password.should be_nil
    end
  end

  context "Rails configuration defaults" do
    let(:rails_root) do
      "/foo/bar"
    end

    subject do 
      Adhearsion::Configuration.new.tap{|config| config.load_rails_configuration({:path => rails_root, :env => "production"})}.rails
    end

    it "should require the path to the Rails app in the constructor" do
      subject.rails_root.should == rails_root
    end

    it "should raise an exception when no env is specified" do
      lambda { 
        Adhearsion::Configuration.new.tap{|config| config.load_rails_configuration({:path => rails_root})}
        }.should raise_error ArgumentError, "Must supply an :env argument to the Rails initializer!"
    end
  end

  context "Database configuration defaults" do

    let(:base_options) do
      { :adapter  => "mysql",
        :host     => "localhost",
        :port     => "3306",
        :user     => "foo",
        :pass     => "bar",
        :database => "adhearsion_app"}
    end

    subject do 
      Adhearsion::Configuration.new.tap{ |config| config.load_database_configuration(base_options)}.database
    end

    its (:connection_options) { should == base_options}

    its (:orm) { should == :active_record}

    it "should remove the :orm key from the connection options" do
      sample_options = base_options.merge({ :orm => :active_record })
      config = Adhearsion::Configuration.new.tap{ |config| config.load_database_configuration(sample_options)}.database
      config.orm.should == sample_options.delete(:orm)

      config.connection_options.should == sample_options
    end
  end

  context "XMPP configuration defaults" do

    let :base_options do
      { :jid => "test@example.com", :password => "somepassword", :server => "example.com" }
    end

    subject do 
      Adhearsion::Configuration.new.tap{ |config| config.load_xmpp_configuration(base_options)}.xmpp
    end

    its(:port) { should == 5222}

    its(:jid) { should == "test@example.com"}

    its(:password) { should == "somepassword"}

    its(:server) { should == "example.com"}

    it "should raise an exception when no server is specified" do
      lambda {
        Adhearsion::Configuration.new.tap{ |config| config.load_xmpp_configuration({:jid => "test@example.com", :password => "somepassword"})}
      }.should raise_error ArgumentError, "Must supply a :server argument to the XMPP initializer!"
    end
  end

  context "Punchblock configuration" do
    describe "with config specified" do
      subject do
        Adhearsion::Configuration.new.tap do |config| 
          config.load_punchblock_configuration(:username => 'userb@127.0.0.1', :password => 'abc123', :auto_reconnect => false)
        end.punchblock.connection_options
      end

      its([:username]) { should == 'userb@127.0.0.1' }
      its([:password]) { should == 'abc123' }
      its([:auto_reconnect]) {should == false }
    end

    describe "with defaults" do
      subject do
        Adhearsion::Configuration.new.tap do |config| 
          config.load_punchblock_configuration
        end.punchblock.connection_options
      end

      its([:username]) { should == 'usera@127.0.0.1' }
      its([:password]) { should == '1' }
      its([:auto_reconnect]) {should == true }
    end
  end

  context "Configuration scenarios" do
    subject do
      Adhearsion::Configuration.new.tap do |config| 
        config.load_punchblock_configuration(:username => 'userb@127.0.0.1', :password => 'abc123', :auto_reconnect => false)
      end.tap do |config|
        config.asterisk.enable_ami
      end.tap do |config|
        config.load_drb_configuration
      end
    end
    
    it "should enable ami with the default values" do
      subject.asterisk.ami_enabled?.should == true
      [:port, :events, :host, :auto_reconnect].each do |value|
        subject.asterisk.ami.send(value).should == subject.asterisk.default_ami.send(value)
      end
      subject.asterisk.ami.should be_a_kind_of Adhearsion::BasicConfiguration
      subject.asterisk.default_ami.should be_a_kind_of Adhearsion::BasicConfiguration
    end

    it "should enable ami with custom configuration and overrides the defaults" do
      subject.asterisk.enable_ami({:port => 911, :events => true, :host => "127.0.0.1", :auto_reconnect => false})
      subject.asterisk.ami.port.should == 911
      subject.asterisk.ami.events.should == true
      subject.asterisk.ami.host.should == "127.0.0.1"
      subject.asterisk.ami.auto_reconnect.should == false
    end

    it "should enable drb with the default values" do
      subject.drb.should_not == nil
      subject.drb.should be_a_kind_of Adhearsion::BasicConfiguration
      subject.drb.port.should == 9050
      subject.drb.host.should == "localhost"
      subject.drb.acl.should == %w[allow 127.0.0.1]
    end

    it "should enable drb with custom configuration and overrides the defaults" do
      subject.load_drb_configuration({:port => 9051, :host => "127.0.0.1", :raw_acl => :this_is_an_acl})
      subject.drb.should be_a_kind_of Adhearsion::BasicConfiguration
      subject.drb.port.should == 9051
      subject.drb.host.should == "127.0.0.1"
      subject.drb.acl.should  == :this_is_an_acl
    end

    it "should enable drb with custom configuration and overrides the defaults with arrays of allow and deny as acl" do
      subject.load_drb_configuration({:port => 9051, :host => "127.0.0.1", :allow => %w[1.1.1.1  2.2.2.2], :deny  => %w[9.9.9.9]})
      subject.drb.should be_a_kind_of Adhearsion::BasicConfiguration
      subject.drb.port.should == 9051
      subject.drb.host.should == "127.0.0.1"
      subject.drb.acl.should  == %w[deny 9.9.9.9 allow 1.1.1.1 allow 2.2.2.2]
    end
    it "should enable drb with custom configuration and overrides the defaults with a String of allow and deny as acl" do
      subject.load_drb_configuration({:port => 9051, :host => "127.0.0.1", :allow => "1.1.1.1", :deny  => "9.9.9.9"})
      subject.drb.should be_a_kind_of Adhearsion::BasicConfiguration
      subject.drb.port.should == 9051
      subject.drb.host.should == "127.0.0.1"
      subject.drb.acl.should  == %w[deny 9.9.9.9 allow 1.1.1.1]
    end

  end

  context "Adhearsion.config" do
    before do
      Adhearsion.config = nil
    end

    it "should initialize to Adhearsion::Configuration" do
      Adhearsion.config.should be_a_kind_of(Adhearsion::Configuration)
    end

  end
end
