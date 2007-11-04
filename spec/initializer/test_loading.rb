require File.dirname(__FILE__) + "/../test_helper"
require 'adhearsion/initializer/database'
require 'adhearsion/initializer/asterisk'
require 'active_record'

context "The database initializer" do
  
  include DatabaseInitializationTestHelper
  
  test "starts a connection through ActiveRecord" do
    connection_options = { :adapter => "sqlite3",
                           :dbfile => "foo.sqlite3" }
    flexmock(Adhearsion::Initializer::DatabaseInitializer).should_receive(:require_models).once
    flexmock(ActiveRecord::Base).should_receive(:establish_connection).with(connection_options)
    
    start_database_initializer_with_options connection_options
  end
  
  test "should make any required models available in the main namespace" do
    bogus_model = tempfile_with_contents sample_user_model
    flexmock(Adhearsion::Initializer::DatabaseInitializer).should_receive(:all_models).and_return([bogus_model.path])
    start_database_initializer
    User.superclass.should.equal ActiveRecord::Base
  end
  
end

context "The Asterisk initializer" do
  
  include AsteriskInitializerTestHelper
  
  test "starts the AGI server" do
    initialize_asterisk_with_defaults
    flexmock(Adhearsion::VoIP::Asterisk::AGI::Server).new_instances.should_receive(:start).once
  end
  
  test "starts the AGI server with any overridden settings" do
    overrides        = {:host => "127.0.0.1", :port => 7788}
    config_overrides = {:listening_host => overrides[:host], :listening_port => overrides[:port]}
    initialize_asterisk_with_options config_overrides
    flexmock(Adhearsion::VoIP::Asterisk::AGI::Server).new_instances.should_receive(:start).once.with(overrides)
  end
  
end

BEGIN {
module DatabaseInitializationTestHelper
  
  def start_database_initializer
    start_database_initializer_with_options :adapter => "sqlite3", :dbfile => "foobar.sqlite3"
  end
  
  def start_database_initializer_with_options(options)
    Adhearsion::Configuration.configure { |config| config.enable_database(options) }
    Adhearsion::Initializer::DatabaseInitializer.start
  end
  
  def tempfile_with_contents(contents)
    returning Tempfile.new("bogus_model") do |file|
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
}
