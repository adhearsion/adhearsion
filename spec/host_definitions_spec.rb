require 'spec_helper'
require 'adhearsion/host_definitions'

describe 'HostDefinition' do

  after :each do
    Adhearsion::HostDefinition.clear_definitions!
  end

  it 'when loading from a YAML array, it should pass each nested Hash to the constructor' do
    hosts = [
      {:host => "hostname1", :username => "user", :password => "password"},
      {:host => "hostname2", :username => "user", :password => "password"},
      {:host => "hostname3", :username => "user", :password => "password"}
    ]
    flexmock(Adhearsion::HostDefinition).should_receive(:new).once.with(hosts[0])
    flexmock(Adhearsion::HostDefinition).should_receive(:new).once.with(hosts[1])
    flexmock(Adhearsion::HostDefinition).should_receive(:new).once.with(hosts[2])
    Adhearsion::HostDefinition.import_from_yaml hosts.to_yaml
  end

  it 'should set the @name property to a new UUID when no name is given' do
    definition = {:host => "hostname", :username => "user", :password => "pass"}
    Adhearsion::HostDefinition.new(definition).name.should =~ /^[a-z0-9]{8}-([a-z0-9]{4}-){3}[a-z0-9]{12}$/i
  end

  it 'when loading from YAML keys, it should pass each nested Hash to the constructor with the key as :name' do
    definitions = { :pbx1 => {},
                    :pbx2 => {},
                    :pbx3 => {} }
    definitions.each_pair do |key,value|
      flexmock(Adhearsion::HostDefinition).should_receive(:new).once.with(value.merge(:name => key))
    end
    Adhearsion::HostDefinition.import_from_data_structure(definitions)
  end

  it 'should have an Array class variable named definitions' do
    Adhearsion::HostDefinition.definitions.should be_a_kind_of Array
  end

  it 'should add each HostDefinition to a class variable named @@definitions when instantiated' do
    Adhearsion::HostDefinition.definitions.size.should be 0
    Adhearsion::HostDefinition.new :name => "foobar", :host => "hostname", :username => "user", :password => "password"
    Adhearsion::HostDefinition.definitions.size.should be 1
    Adhearsion::HostDefinition.clear_definitions!
    Adhearsion::HostDefinition.definitions.size.should be 0
  end

  it 'should raise a HostDefinitionException when a password and a key are given' do
    the_following_code {
      Adhearsion::HostDefinition.new(:username => "user", :host => "foobar", :key => "doesntmatter", :password => "pass")
    }.should raise_error Adhearsion::HostDefinition::HostDefinitionException
  end

  it 'should raise a HostDefinitionException when no password or key is given' do
    the_following_code {
      Adhearsion::HostDefinition.new(:username => "user", :host => "foobar")
    }.should raise_error Adhearsion::HostDefinition::HostDefinitionException
  end

  it 'should raise a HostDefinitionException when no username is given' do
    the_following_code {
      Adhearsion::HostDefinition.new(:host => "host", :password => "password")
    }.should raise_error Adhearsion::HostDefinition::HostDefinitionException
  end

  it 'should raise a HostDefinitionException when no "host" key is given' do
    the_following_code {
      Adhearsion::HostDefinition.new(:username => "foobar", :password => "password")
    }.should raise_error Adhearsion::HostDefinition::HostDefinitionException
  end

  it 'should raise a HostDefinitionException when an unrecognized key is given' do
    the_following_code {
      Adhearsion::HostDefinition.new(:username => "foobar", :password => "password", :host => "blah", :thiskeyisnotrecognized => nil)
    }.should raise_error Adhearsion::HostDefinition::HostDefinitionException
  end

end