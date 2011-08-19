require 'spec_helper'
require 'active_record'

describe "The Rails initializer" do

  def initialize_rails_with_options(options)
    rails_options = flexmock "Rails options mock", options
    flexstub(Adhearsion::AHN_CONFIG).should_receive(:rails).once.and_return(rails_options)
    Adhearsion::Initializer::Rails.start
  end

  def stub_file_checking_methods!
    flexstub(File).should_receive(:directory?).and_return true
    flexstub(File).should_receive(:exists?).and_return true
  end

  def stub_before_call_hook!
    flexstub(Adhearsion::Events.framework_theatre).should_receive(:register_namespace_name).with([:before_call]).and_return
  end

  it "should load the config/environment.rb file within the rails_root path" do
    rails_root     = "/path/to/rails/app"
    environment_rb = rails_root + '/config/environment.rb'
    flexmock(Adhearsion::Initializer::Rails).should_receive(:require).once.with environment_rb
    stub_file_checking_methods!
    stub_before_call_hook!
    initialize_rails_with_options :rails_root => rails_root, :environment => :development
  end

  it "should raise an exception if the database is initialized at the same time" do
    flexstub(Adhearsion::AHN_CONFIG).should_receive(:database_enabled?).and_return true
    flexmock(Adhearsion::Initializer::Rails).should_receive(:require).and_return
    stub_file_checking_methods!
    stub_before_call_hook!
    the_following_code {
      initialize_rails_with_options :rails_root => '/tmp', :environment => :development
    }.should raise_error
  end

  it "should set the RAILS_ENV to be the argument passed in" do
    flexmock(Adhearsion::Initializer::Rails).should_receive(:require).once.and_return
    stub_file_checking_methods!
    stub_before_call_hook!
    initialize_rails_with_options :rails_root => '/tmp', :environment => :development
    raise Test::Unit::AssertionFailed, 'ENV["RAILS_ENV"] should have been set but was not.' unless ENV['RAILS_ENV'] == "development"
  end

  it 'should create a BeforeCall hook (presumably to verify the active connections)' do
    flexstub(Adhearsion::Initializer::Rails).should_receive :require
    flexstub(Adhearsion::Initializer::Rails).should_receive :load_rails
    stub_file_checking_methods!
    flexmock(Adhearsion::Events).should_receive(:register_callback).once.with([:before_call], Proc)
    initialize_rails_with_options :rails_root => '/path/somewhere', :environment => :development
  end

end
