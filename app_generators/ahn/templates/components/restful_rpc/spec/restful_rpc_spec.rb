unless defined? Adhearsion
  if File.exists? File.dirname(__FILE__) + "/../../../adhearsion/lib/adhearsion.rb"
    # If you wish to freeze a copy of Adhearsion to this app, simply place a copy of Adhearsion
    # into a folder named "adhearsion" within this app's main directory.
    require File.dirname(__FILE__) + "/../../../adhearsion/lib/adhearsion.rb"
  elsif File.exists? File.dirname(__FILE__) + "/../../../../../../lib/adhearsion.rb"
    # This file may be ran from the within the Adhearsion framework code (before a project has been generated)
    require File.dirname(__FILE__) + "/../../../../../../lib/adhearsion.rb"
  else
    require 'rubygems'
    gem 'adhearsion', '>= 0.7.999'
    require 'adhearsion'
  end
end

require 'adhearsion/component_manager/spec_framework'

RESTFUL_RPC = ComponentTester.new("restful_rpc", File.dirname(__FILE__) + "/../..")

describe "The VALID_IP_ADDRESS regular expression" do
  
  it "should match only valid IP addresses" do
    valid_ip_addresses   = ["192.168.1.98", "10.0.1.200", "255.255.255.0", "123.*.4.*"]
    invalid_ip_addresses = ["10.0.1.1 foo", "bar 255.255.255.0", "0*0*0*0", "1234"]
    
    valid_ip_addresses.  each { |ip| RESTFUL_RPC::VALID_IP_ADDRESS.should =~ ip }
    invalid_ip_addresses.each { |ip| RESTFUL_RPC::VALID_IP_ADDRESS.should_not =~ ip }
  end
end

describe "The initialization block" do
  it "should create a new Thread"
  it "should create a new Rack adapter"
end

describe 'Private helper methods' do

  describe "serve() method" do
    
    it "should return a 200 for requests which execute a method that has been defined in the methods_for(:rpc) context" do
      pending "damnit"
    end
    
    it "should contain backtrace information when show_errors is enabled and an exception occurs"
    
  end
  
  describe 'ip_allowed?()' do
    
    before :each do
      @method = RESTFUL_RPC.helper_method :ip_allowed?
    end
    
    it 'should raise a ConfigurationError if "access" is not one of "everyone", "whitelist" or "blacklist"'
    
    describe 'whitelists' do
      
      after(:each) { RESTFUL_RPC.config["whitelist"].clear }
      
      it "should parse *'s as wildcards" do
        use_patterns_for_whitelist "10.0.0.0"
        @method.call("0.0.0.0").should equal(true)
      end
      
      def use_patterns_for_whitelist(*allowed_patterns)
        mock(RESTFUL_RPC).config { {:foo => "bar"} }
      end
      
    end
    
    describe 'blacklists' do
      
    end
    
    describe '"everyone" access' do
      it "should return true for any IP given" do
        ip_addresses = %w[100.200.100.200 0.0.0.0 *.0.0.*]
        ip_addresses.each do |address|
          RESTFUL_RPC.helper_method(:ip_allowed?).call(address).should.equal true
        end
      end
    end
    
  end
end
