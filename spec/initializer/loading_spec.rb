require 'spec_helper'
require 'adhearsion/initializer/database'
require 'adhearsion/initializer/asterisk'
require 'adhearsion/initializer/rails'
require 'adhearsion/initializer/xmpp'
require 'active_record'

module DatabaseInitializationTestHelper

  def start_database_initializer
    start_database_initializer_with_options :adapter => "sqlite3", :dbfile => "foobar.sqlite3"
  end

  def start_database_initializer_with_options(options)
    Adhearsion::Configuration.configure { |config| config.enable_database(options) }
    Adhearsion::Initializer::DatabaseInitializer.start
  end

  def tempfile_with_contents(contents)
    Tempfile.new("bogus_model").tap do |file|
      file.puts contents
      file.flush
    end
  end

  def sample_user_model
    <<-CODE
      class User < ActiveRecord::Base
        validates_uniqueness_of :name
      end
    CODE
  end
end

module AsteriskInitializerTestHelper
  def initialize_asterisk_with_defaults
    initialize_asterisk_with_options Hash.new
  end
  def initialize_asterisk_with_options(options)
    flexmock(Adhearsion::Initializer::AsteriskInitializer).should_receive(:join_server_thread_after_initialized)
    Adhearsion::Configuration.configure { |config| config.enable_asterisk(options) }
    Adhearsion::Initializer::AsteriskInitializer.start
  end
end

module RailsInitializerTestHelper

  def initialize_rails_with_options(options)
    rails_options = flexmock "Rails options mock", options
    flexstub(Adhearsion::AHN_CONFIG).should_receive(:rails).once.and_return(rails_options)
    Adhearsion::Initializer::RailsInitializer.start
  end

  def stub_file_checking_methods!
    flexstub(File).should_receive(:directory?).and_return true
    flexstub(File).should_receive(:exists?).and_return true
  end

  def stub_before_call_hook!
    flexstub(Adhearsion::Events.framework_theatre).should_receive(:register_namespace_name).with([:asterisk, :before_call]).and_return
  end

end

describe "The database initializer" do

  include DatabaseInitializationTestHelper

  after :each do
    Adhearsion.send(:remove_const, :AHN_CONFIG) if Adhearsion.const_defined? :AHN_CONFIG
  end

  it "starts a connection through ActiveRecord" do
    connection_options = { :adapter => "sqlite3",
                           :dbfile => "foo.sqlite3" }
    flexmock(Adhearsion::Initializer::DatabaseInitializer).should_receive(:require_models).once
    flexmock(ActiveRecord::Base).should_receive(:establish_connection).with(connection_options)

    start_database_initializer_with_options connection_options
  end

  it "should make any required models available in the main namespace" do
    bogus_model = tempfile_with_contents sample_user_model
    flexmock(Adhearsion::Configuration).new_instances.should_receive(:files_from_setting).once.
        with("paths", "models").and_return [bogus_model.path]
    start_database_initializer
    User.superclass.should be ActiveRecord::Base
  end

end

describe "The Asterisk initializer" do

  include AsteriskInitializerTestHelper

  it "starts the AGI server" do
    initialize_asterisk_with_defaults
    flexmock(Adhearsion::VoIP::Asterisk::AGI::Server).new_instances.should_receive(:start).once
  end

  it "starts the AGI server with any overridden settings" do
    overrides        = {:host => "127.0.0.1", :port => 7788}
    config_overrides = {:listening_host => overrides[:host], :listening_port => overrides[:port]}
    initialize_asterisk_with_options config_overrides
    flexmock(Adhearsion::VoIP::Asterisk::AGI::Server).new_instances.should_receive(:start).once.with(overrides)
  end

end

describe "The Rails initializer" do

  include RailsInitializerTestHelper

  it "should load the config/environment.rb file within the rails_root path" do
    rails_root     = "/path/to/rails/app"
    environment_rb = rails_root + '/config/environment.rb'
    flexmock(Adhearsion::Initializer::RailsInitializer).should_receive(:require).once.with environment_rb
    stub_file_checking_methods!
    stub_before_call_hook!
    initialize_rails_with_options :rails_root => rails_root, :environment => :development
  end

  it "should raise an exception if the database is initialized at the same time" do
    flexstub(Adhearsion::AHN_CONFIG).should_receive(:database_enabled?).and_return true
    flexmock(Adhearsion::Initializer::RailsInitializer).should_receive(:require).and_return
    stub_file_checking_methods!
    stub_before_call_hook!
    the_following_code {
      initialize_rails_with_options :rails_root => '/tmp', :environment => :development
    }.should raise_error
  end

  it "should set the RAILS_ENV to be the argument passed in" do
    flexmock(Adhearsion::Initializer::RailsInitializer).should_receive(:require).once.and_return
    stub_file_checking_methods!
    stub_before_call_hook!
    initialize_rails_with_options :rails_root => '/tmp', :environment => :development
    raise Test::Unit::AssertionFailed, 'ENV["RAILS_ENV"] should have been set but was not.' unless ENV['RAILS_ENV'] == "development"
  end

  it 'should create a BeforeCall hook (presumably to verify the active connections)' do
    flexstub(Adhearsion::Initializer::RailsInitializer).should_receive :require
    flexstub(Adhearsion::Initializer::RailsInitializer).should_receive :load_rails
    stub_file_checking_methods!
    flexmock(Adhearsion::Events).should_receive(:register_callback).once.with([:asterisk, :before_call], Proc)
    initialize_rails_with_options :rails_root => '/path/somewhere', :environment => :development
  end

end
