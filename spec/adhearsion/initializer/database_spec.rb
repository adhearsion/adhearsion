require 'spec_helper'
require 'active_record'

describe "The database initializer" do

  def start_database_initializer
    start_database_initializer_with_options :adapter => "sqlite3", :dbfile => "foobar.sqlite3"
  end

  def start_database_initializer_with_options(options)
    Adhearsion.config do |config| 
      config.load_database_configuration(options)
    end
    Adhearsion::Initializer::Database.start
  end

  def expect_establish_connection
    flexmock(ActiveRecord::Base).should_receive :establish_connection
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

  after :each do
    Adhearsion.config = nil
    Adhearsion.config
  end

  it "starts a connection through ActiveRecord" do
    connection_options = { :adapter => "sqlite3", :dbfile => "foo.sqlite3" }
    flexmock(Adhearsion::Initializer::Database).should_receive(:require_models).once
    expect_establish_connection.with connection_options

    start_database_initializer_with_options connection_options
  end

  it "should make any required models available in the main namespace" do
    bogus_model = tempfile_with_contents sample_user_model
    flexmock(Adhearsion.config).should_receive(:files_from_setting).once.
        with("paths", "models").and_return [bogus_model.path]
    expect_establish_connection
    start_database_initializer
    User.superclass.should be ActiveRecord::Base
  end

end
