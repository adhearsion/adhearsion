require File.dirname(__FILE__) + "/../test_helper"

context "Configuration defaults" do
  include ConfigurationTestHelper
  attr_reader :config
  
  setup do
    @config = default_config
  end
  
  test "incoming calls are answered by default" do
    assert config.automatically_answer_incoming_calls
  end
  
  test "calls are ended when hung up" do
    assert config.end_call_on_hangup
  end
  
  test "if an error occurs, a call is hungup" do
    assert config.end_call_on_error
  end
  
  test "asterisk is enabled by default" do
    assert config.asterisk_enabled?
  end
  
  test "default asterisk configuration is available" do
    assert_kind_of Adhearsion::Configuration::AsteriskConfiguration, config.asterisk
  end
  
  test "database access is NOT enabled by default" do
    assert !config.database_enabled?
  end
  
  test "freeswith is NOT enabled by default" do
    assert !config.freeswitch_enabled?
  end
  
  test "AMI is NOT enabled by default" do
    assert !config.asterisk.ami_enabled?
  end
  
  test "Drb is NOT enabled by default" do
    assert !config.drb_enabled?
  end
end

context "Asterisk configuration defaults" do
  attr_reader :config
  
  setup do
    @config = Adhearsion::Configuration::AsteriskConfiguration.new
  end
  
  test "asterisk configuration sets default listening port" do
    config.listening_port.should.equal Adhearsion::Configuration::AsteriskConfiguration.default_listening_port
  end
  
  test "asterisk configuration sets default listening host" do
    config.listening_host.should.equal Adhearsion::Configuration::AsteriskConfiguration.default_listening_host
  end
end

context "AMI configuration defaults" do
  attr_reader :config
  
  setup do
    @config = Adhearsion::Configuration::AsteriskConfiguration::AMIConfiguration.new
  end
  
  test "ami configuration sets default port" do
    config.port.should.equal Adhearsion::Configuration::AsteriskConfiguration::AMIConfiguration.default_port
  end
  
  test "ami allows you to configure a username and a password, both of which default to nil" do
    config.username.should.be.nil
    config.password.should.be.nil
  end
end

context "Database configuration defaults" do
  
  setup do
    Adhearsion.send(:remove_const, :AHN_CONFIG) if Adhearsion.const_defined?(:AHN_CONFIG)
    Adhearsion::Configuration.configure {}
  end
  
  it "should store the constructor's argument in connection_options()" do
    sample_options = { :adapter => "sqlite3", :dbfile => "foo.sqlite3" }
    config = Adhearsion::Configuration::DatabaseConfiguration.new(sample_options)
    config.connection_options.should.equal sample_options
  end
  it "should remove the :orm key from the connection options" do
    sample_options = { :orm => :active_record, :adapter => "mysql", :host => "::1",
                       :user => "a", :pass => "b", :database => "ahn" }
    config = Adhearsion::Configuration::DatabaseConfiguration.new(sample_options.clone)
    config.orm.should.equal sample_options.delete(:orm)
    config.connection_options.should.equal sample_options
  end
end

context "Freeswitch configuration defaults" do
  attr_reader :config
  
  setup do
    @config = Adhearsion::Configuration::FreeswitchConfiguration.new
  end
  
  test "freeswitch configuration sets default listening port" do
    config.listening_port.should.equal Adhearsion::Configuration::FreeswitchConfiguration.default_listening_port
  end
  
  test "freeswitch configuration sets default listening host" do
    config.listening_host.should.equal Adhearsion::Configuration::FreeswitchConfiguration.default_listening_host
  end
end

context "Configuration scenarios" do
  include ConfigurationTestHelper
  
  test "enabling AMI using all its defaults" do
    config = enable_ami
    
    assert config.asterisk.ami_enabled?
    config.asterisk.ami.should.be.kind_of Adhearsion::Configuration::AsteriskConfiguration::AMIConfiguration
  end
  
  test "enabling AMI with custom configuration overrides the defaults" do
    overridden_port = 911
    config = enable_ami :port => overridden_port
    config.asterisk.ami.port.should.equal overridden_port
  end
  
  test "enabling Drb without any configuration" do
    config = enable_drb
    assert config.drb
    config.drb.should.be.kind_of Adhearsion::Configuration::DrbConfiguration
  end
  
  test "enabling Drb with a port specified sets the port" do
    target_port = 911
    config = enable_drb :port => target_port
    config.drb.port.should.be.equal target_port
  end
  
  private
    def enable_ami(*overrides)
      default_config do |config|
        config.asterisk.enable_ami *overrides
      end
    end
    
    def enable_drb(*overrides)
      default_config do |config|
        config.enable_drb *overrides
      end
    end
end

context "AHN_CONFIG" do
  setup do
    Adhearsion.send(:remove_const, :AHN_CONFIG) if Adhearsion.const_defined?(:AHN_CONFIG)
  end
  
  test "Running configure sets configuration to Adhearsion::AHN_CONFIG" do
    assert !Adhearsion.const_defined?(:AHN_CONFIG)
    Adhearsion::Configuration.configure do |config|
      # Nothing needs to happen here
    end
    
    assert Adhearsion.const_defined?(:AHN_CONFIG)
    Adhearsion::AHN_CONFIG.should.be.kind_of(Adhearsion::Configuration)
  end
end

BEGIN {
  module ConfigurationTestHelper
    def default_config(&block)
      Adhearsion::Configuration.new do |config|
        config.enable_asterisk
        yield config if block_given?
      end
    end
  end
}