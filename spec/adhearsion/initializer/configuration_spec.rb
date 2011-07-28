require 'spec_helper'

module ConfigurationTestHelper
  def default_config(&block)
    Adhearsion::Configuration.new do |config|
      config.enable_asterisk
      yield config if block_given?
    end
  end
end

describe "Configuration defaults" do
  include ConfigurationTestHelper
  attr_reader :config

  before(:each) do
    @config = default_config
  end

  it "incoming calls are answered by default" do
    config.automatically_answer_incoming_calls.should be true
  end

  it "calls are ended when hung up" do
    config.end_call_on_hangup.should be true
  end

  it "if an error occurs, a call is hungup" do
    config.end_call_on_error.should be true
  end

  it "asterisk is enabled by default" do
    config.asterisk_enabled?.should be true
  end

  it "default asterisk configuration is available" do
    config.asterisk.kind_of?(Adhearsion::Configuration::AsteriskConfiguration).should be true
  end

  it "database access is NOT enabled by default" do
    config.database_enabled?.should be false
  end

  it "ldap access is NOT enabled by default" do
    config.ldap_enabled?.should be false
  end

  it "freeswith is NOT enabled by default" do
    config.freeswitch_enabled?.should be false
  end

  it "AMI is NOT enabled by default" do
    config.asterisk.ami_enabled?.should be false
  end

  it "Drb is NOT enabled by default" do
    config.drb_enabled?.should be false
  end

  it "XMPP is NOT enabled by default" do
    config.xmpp_enabled?.should be false
  end
end

describe "Asterisk AGI configuration defaults" do
  attr_reader :config

  before(:each) do
    @config = Adhearsion::Configuration::AsteriskConfiguration.new
  end

  it "asterisk configuration sets default listening port" do
    config.listening_port.should be Adhearsion::Configuration::AsteriskConfiguration.default_listening_port
  end

  it "asterisk configuration sets default listening host" do
    config.listening_host.should == Adhearsion::Configuration::AsteriskConfiguration.default_listening_host
  end
end

describe 'Logging configuration' do

  attr_reader :config
  before :each do
    @config = Adhearsion::Configuration.new
  end

  after :each do
    Adhearsion::Logging.logging_level = :fatal
    Adhearsion::Logging::AdhearsionLogger.outputters = [Log4r::Outputter.stdout]
    Adhearsion::Logging::AdhearsionLogger.formatters = [Log4r::DefaultFormatter]
  end

  it 'the logging level should translate from symbols into Log4r constants' do
    Adhearsion::Logging.logging_level.should_not be Log4r::WARN
    config.logging :level => :warn
    Adhearsion::Logging.logging_level.should be Log4r::WARN
  end

  it 'outputters should be settable' do
    Adhearsion::Logging::AdhearsionLogger.outputters.should == [Log4r::Outputter.stdout]
    config.logging :outputters => Log4r::Outputter.stderr
    Adhearsion::Logging::AdhearsionLogger.outputters.should == [Log4r::Outputter.stderr]
  end

  it 'formatters should be settable' do
    Adhearsion::Logging::AdhearsionLogger.formatters.map(&:class).should == [Log4r::DefaultFormatter]
    config.logging :formatters => Log4r::ObjectFormatter
    Adhearsion::Logging::AdhearsionLogger.formatters.map(&:class).should == [Log4r::ObjectFormatter]
  end

  it 'a global formatter should be settable' do
    Adhearsion::Logging::AdhearsionLogger.outputters << Log4r::Outputter.stdout
    Adhearsion::Logging::AdhearsionLogger.formatters.map(&:class).should == [Log4r::DefaultFormatter, Log4r::DefaultFormatter]
    config.logging :formatter => Log4r::ObjectFormatter
    Adhearsion::Logging::AdhearsionLogger.formatters.map(&:class).should == [Log4r::ObjectFormatter, Log4r::ObjectFormatter]
  end

end

describe "AMI configuration defaults" do
  attr_reader :config

  before(:each) do
    @config = Adhearsion::Configuration::AsteriskConfiguration::AMIConfiguration.new
  end

  it "ami configuration sets default port" do
    config.port.should be Adhearsion::Configuration::AsteriskConfiguration::AMIConfiguration.default_port
  end

  it "ami allows you to configure a username and a password, both of which default to nil" do
    config.username.should be nil
    config.password.should be nil
  end
end

describe "Rails configuration defaults" do
  it "should require the path to the Rails app in the constructor" do
    config = Adhearsion::Configuration::RailsConfiguration.new :path => "path here doesn't matter right now", :env => :development
    config.rails_root.should_not be nil
  end

  it "should expand_path() the first constructor parameter" do
    rails_root = "gui"
    flexmock(File).should_receive(:expand_path).once.with(rails_root)
    config = Adhearsion::Configuration::RailsConfiguration.new :path => rails_root, :env => :development
  end
end

describe "Database configuration defaults" do

  before(:each) do
    Adhearsion.send(:remove_const, :AHN_CONFIG) if Adhearsion.const_defined?(:AHN_CONFIG)
    Adhearsion::Configuration.configure {}
  end

  it "should store the constructor's argument in connection_options()" do
    sample_options = { :adapter => "sqlite3", :dbfile => "foo.sqlite3" }
    config = Adhearsion::Configuration::DatabaseConfiguration.new(sample_options)
    config.connection_options.should be sample_options
  end
  it "should remove the :orm key from the connection options" do
    sample_options = { :orm => :active_record, :adapter => "mysql", :host => "::1",
                       :user => "a", :pass => "b", :database => "ahn" }
    config = Adhearsion::Configuration::DatabaseConfiguration.new(sample_options.clone)
    config.orm.should be sample_options.delete(:orm)
    config.connection_options.should == sample_options
  end
end

describe "Freeswitch configuration defaults" do
  attr_reader :config

  before(:each) do
    @config = Adhearsion::Configuration::FreeswitchConfiguration.new
  end

  it "freeswitch configuration sets default listening port" do
    config.listening_port.should be Adhearsion::Configuration::FreeswitchConfiguration.default_listening_port
  end

  it "freeswitch configuration sets default listening host" do
    config.listening_host.should == Adhearsion::Configuration::FreeswitchConfiguration.default_listening_host
  end
end

describe "XMPP configuration defaults" do
  attr_reader :config

  it "xmpp configuration sets default port when server is set, but no port" do
    config = Adhearsion::Configuration::XMPPConfiguration.new :jid => "test@example.com", :password => "somepassword", :server => "example.com"
    config.port.should be Adhearsion::Configuration::XMPPConfiguration.default_port
  end

  it "should raise when port is specified, but no server" do
    begin
      config = Adhearsion::Configuration::XMPPConfiguration.new :jid => "test@example.com", :password => "somepassword", :port => "5223"
    rescue ArgumentError => e
      e.message.should == "Must supply a :server argument as well as :port to the XMPP initializer!"
    end
  end
end

describe "Configuration scenarios" do
  include ConfigurationTestHelper

  it "enabling AMI using all its defaults" do
    config = enable_ami

    config.asterisk.ami_enabled?.should be true
    config.asterisk.ami.should be_a_kind_of Adhearsion::Configuration::AsteriskConfiguration::AMIConfiguration
  end

  it "enabling AMI with custom configuration overrides the defaults" do
    overridden_port = 911
    config = enable_ami :port => overridden_port
    config.asterisk.ami.port.should be overridden_port
  end

  it "enabling Drb without any configuration" do
    config = enable_drb
    config.drb.should_not be nil
    config.drb.should be_a_kind_of Adhearsion::Configuration::DrbConfiguration
  end

  it "enabling Drb with a port specified sets the port" do
    target_port = 911
    config = enable_drb :port => target_port
    config.drb.port.should == target_port
  end

  private
    def enable_ami(*overrides)
      default_config do |config|
        config.asterisk.enable_ami(*overrides)
      end
    end

    def enable_drb(*overrides)
      default_config do |config|
        config.enable_drb *overrides
      end
    end
end

describe "AHN_CONFIG" do
  before(:each) do
    Adhearsion.send(:remove_const, :AHN_CONFIG) if Adhearsion.const_defined?(:AHN_CONFIG)
  end

  it "Running configure sets configuration to Adhearsion::AHN_CONFIG" do
    Adhearsion.const_defined?(:AHN_CONFIG).should be false
    Adhearsion::Configuration.configure do |config|
      # Nothing needs to happen here
    end

    Adhearsion.const_defined?(:AHN_CONFIG).should be true
    Adhearsion::AHN_CONFIG.should be_a_kind_of(Adhearsion::Configuration)
  end
end

describe "DRb configuration" do
  it "should not add any ACL rules when :raw_acl is passed in" do
    config = Adhearsion::Configuration::DrbConfiguration.new :raw_acl => :this_is_an_acl
    config.acl.should be :this_is_an_acl
  end

  it "should, by default, allow only localhost connections" do
    config = Adhearsion::Configuration::DrbConfiguration.new
    config.acl.should == %w[allow 127.0.0.1]
  end

  it "should add ACL 'deny' rules before 'allow' rules" do
    config = Adhearsion::Configuration::DrbConfiguration.new :allow => %w[1.1.1.1  2.2.2.2],
                                                             :deny  => %w[9.9.9.9]
    config.acl.should == %w[deny 9.9.9.9 allow 1.1.1.1 allow 2.2.2.2]
  end

  it "should allow both an Array and a String to be passed as an allow/deny ACL rule" do
    config = Adhearsion::Configuration::DrbConfiguration.new :allow => "1.1.1.1", :deny => "9.9.9.9"
    config.acl.should == %w[deny 9.9.9.9 allow 1.1.1.1]
  end

  it "should have a default host and port" do
    config = Adhearsion::Configuration::DrbConfiguration.new
    config.host.should_not be nil
    config.port.should_not be nil
  end

end
