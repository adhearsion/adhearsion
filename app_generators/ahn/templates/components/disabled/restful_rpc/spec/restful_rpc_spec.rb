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

##### This is here for a reference
#{"CONTENT_LENGTH"       => "12",
# "CONTENT_TYPE"         => "application/x-www-form-urlencoded",
# "GATEWAY_INTERFACE"    => "CGI/1.1",
# "HTTP_ACCEPT"          => "application/xml",
# "HTTP_ACCEPT_ENCODING" => "gzip, deflate",
# "HTTP_AUTHORIZATION"   => "Basic amlja3N0YTpyb2ZsY29wdGVyeg==",
# "HTTP_HOST"            => "localhost:5000",
# "HTTP_VERSION"         => "HTTP/1.1",
# "PATH_INFO"            => "/rofl",
# "QUERY_STRING"         => "",
# "rack.errors"          => StringIO.new(""),
# "rack.input"           => StringIO.new('["o","hai!"]'),
# "rack.multiprocess"    => false,
# "rack.multithread"     => true,
# "rack.run_once"        => false,
# "rack.url_scheme"      => "http",
# "rack.version"         => [0, 1],
# "REMOTE_ADDR"          => "::1",
# "REMOTE_HOST"          => "localhost",
# "REMOTE_USER"          => "jicksta",
# "REQUEST_METHOD"       => "POST"
# "REQUEST_PATH"         => "/",
# "REQUEST_URI"          => "http://localhost:5000/rofl",
# "SCRIPT_NAME"          => "",
# "SERVER_NAME"          => "localhost",
# "SERVER_PORT"          => "5000",
# "SERVER_PROTOCOL"      => "HTTP/1.1",
# "SERVER_SOFTWARE"      => "WEBrick/1.3.1 (Ruby/1.8.6/2008-03-03)"}



describe "The VALID_IP_ADDRESS regular expression" do
  
  it "should match only valid IP addresses" do
    valid_ip_addresses   = ["192.168.1.98", "10.0.1.200", "255.255.255.0", "123.*.4.*"]
    invalid_ip_addresses = ["10.0.1.1 foo", "bar 255.255.255.0", "0*0*0*0", "1234"]
    
    valid_ip_addresses.  each { |ip| RESTFUL_RPC::VALID_IP_ADDRESS.should =~ ip }
    invalid_ip_addresses.each { |ip| RESTFUL_RPC::VALID_IP_ADDRESS.should_not =~ ip }
  end
end

describe "The initialization block" do
  
  it "should create a new Thread" do
    mock_component_config_with :restful_rpc => {}
    mock(Thread).new { nil }
    RESTFUL_RPC.initialize!
  end
  
  it "should run the Rack adapter specified in the configuration" do
    mock(Thread).new.yields
    mock_component_config_with :restful_rpc => {"adapter" => "Mongrel"}
    mock(Rack::Handler::Mongrel).run is_a(Proc), :Port => 5000
    RESTFUL_RPC.initialize!
  end
  
  it "should wrap the RESTFUL_API_HANDLER in an Rack::Auth::Basic object if authentication is enabled" do
    mock(Thread).new.yields
    mock_component_config_with :restful_rpc => {"authentication" => {"foo" => "bar"}}
    
    proper_authenticator = lambda do |obj|
      request = OpenStruct.new :credentials => ["foo", "bar"]
      obj.is_a?(Rack::Auth::Basic) && obj.send(:valid?, request)
    end
    
    mock(Rack::Handler::Mongrel).run(satisfy(&proper_authenticator), :Port => 5000)
    RESTFUL_RPC.initialize!
  end
  
  it 'should wrap the RESTFUL_API_HANDLER in ShowStatus and ShowExceptions objects when show_exceptions is enabled' do
    mock(Thread).new.yields
    mock_component_config_with :restful_rpc => {"show_exceptions" => true}
    
    mock.proxy(Rack::ShowExceptions).new(is_a(Proc))
    mock.proxy(Rack::ShowStatus).new is_a(Rack::ShowExceptions)
    
    mock(Rack::Handler::Mongrel).run is_a(Rack::ShowStatus), :Port => 5000
    RESTFUL_RPC.initialize!
  end
  
end

describe 'Private helper methods' do

  describe "the RESTFUL_API_HANDLER lambda" do
    
    it "should return a 200 for requests which execute a method that has been defined in the methods_for(:rpc) context" do
      component_manager = Adhearsion::Components::ComponentManager.new('/path/shouldnt/matter')

      mock(Adhearsion::Components).component_manager { component_manager }
      component_manager.load_code <<-RUBY
        methods_for(:rpc) do
          def testing_123456(one,two)
            [two.reverse, one.reverse]
          end
        end
      RUBY
    
      input = StringIO.new %w[jay phillips].to_json
      
      mock_component_config_with :restful_rpc => {"path_nesting" => "/"}
      
      env = {"PATH_INFO" => "/testing_123456", "rack.input" => input}
    
      response = RESTFUL_RPC::RESTFUL_API_HANDLER.call(env)
      response.should be_kind_of(Array)
      response.should have(3).items
      response.first.should equal(200)
      JSON.parse(response.last).should eql(%w[jay phillips].map(&:reverse).reverse)
    end
    
    it "should return a 400 when no data is POSTed" do
      env = {"rack.input" => StringIO.new(""), "REQUEST_URI" => "/foobar"}
      RESTFUL_RPC::RESTFUL_API_HANDLER.call(env).first.should equal(400)
    end
    
    it "should work with a high level test of a successful method invocation" do
      
      component_manager = Adhearsion::Components::ComponentManager.new('/path/shouldnt/matter')

      mock(Adhearsion::Components).component_manager { component_manager }
      
      component_manager.load_code '
        methods_for(:rpc) do
          def rofl(one,two)
            "Hai! #{one} #{two}"
          end
        end'
      
      env = {
        "CONTENT_LENGTH"       => "12",
        "CONTENT_TYPE"         => "application/x-www-form-urlencoded",
        "GATEWAY_INTERFACE"    => "CGI/1.1",
        "HTTP_ACCEPT"          => "application/xml",
        "HTTP_ACCEPT_ENCODING" => "gzip, deflate",
        "HTTP_AUTHORIZATION"   => "Basic amlja3N0YTpyb2ZsY29wdGVyeg==",
        "HTTP_HOST"            => "localhost:5000",
        "HTTP_VERSION"         => "HTTP/1.1",
        "PATH_INFO"            => "/rofl",
        "QUERY_STRING"         => "",
        "rack.errors"          => StringIO.new(""),
        "rack.input"           => StringIO.new('["o","hai!"]'),
        "rack.multiprocess"    => false,
        "rack.multithread"     => true,
        "rack.run_once"        => false,
        "rack.url_scheme"      => "http",
        "rack.version"         => [0, 1],
        "REMOTE_ADDR"          => "::1",
        "REMOTE_HOST"          => "localhost",
        "REMOTE_USER"          => "jicksta",
        "REQUEST_METHOD"       => "POST",
        "REQUEST_PATH"         => "/",
        "REQUEST_URI"          => "http://localhost:5000/rofl",
        "SCRIPT_NAME"          => "",
        "SERVER_NAME"          => "localhost",
        "SERVER_PORT"          => "5000",
        "SERVER_PROTOCOL"      => "HTTP/1.1",
        "SERVER_SOFTWARE"      => "WEBrick/1.3.1 (Ruby/1.8.6/2008-03-03)" }
      
      response = RESTFUL_RPC::RESTFUL_API_HANDLER.call(env)
      JSON.parse(response.last).should == ["Hai! o hai!"]
      
    end
    
    it "should contain backtrace information when show_errors is enabled and an exception occurs" do
      mock_component_config_with :restful_api => {"show_errors" => true}
      pending
    end
    
  end
  
  describe 'the ip_allowed?() method' do
    
    before :each do
      @method = RESTFUL_RPC.helper_method :ip_allowed?
    end
    
    it 'should raise a ConfigurationError if "access" is not one of "everyone", "whitelist" or "blacklist"' do
      good_access_values = %w[everyone whitelist blacklist]
      bad_access_values  = %w[foo bar qaz qwerty everone blaclist whitlist]
      
      good_access_values.each do |access_value|
        mock_component_config_with :restful_rpc => {"access" => access_value, "whitelist" => [], "blacklist" => []}
        lambda { @method.call("10.0.0.1") }.should_not raise_error
      end
      
      bad_access_values.each do |access_value|
        mock_component_config_with :restful_rpc => {"access" => access_value, "authentication" => false}
        lambda { @method.call("10.0.0.1") }.should raise_error(Adhearsion::Components::ConfigurationError)
      end
    end
    
    describe 'whitelists' do
      
      it "should parse *'s as wildcards" do
        mock_component_config_with :restful_rpc => {"access" => "whitelist", "whitelist" => ["10.*.*.*"]}
        @method.call("10.1.2.3").should be_true
      end
      
      it "should allow IPs which are explictly specified" do
        mock_component_config_with :restful_rpc => {"access" => "whitelist", "whitelist" => ["4.3.2.1"]}
        @method.call("4.3.2.1").should be_true
      end
      
      it "should not allow IPs which are not explicitly specified" do
        mock_component_config_with :restful_rpc => {"access" => "whitelist", "whitelist" => %w[ 1.2.3.4 4.3.2.1]}
        @method.call("2.2.2.2").should be_false
      end
      
    end
    
    describe 'blacklists' do
      
      it "should parse *'s as wildcards" do
        mock_component_config_with :restful_rpc => {"access" => "blacklist", "blacklist" => ["10.*.*.*"]}
        @method.call("10.1.2.3").should be_false
      end
      
      it "should not allow IPs which are explicitly specified" do
        mock_component_config_with :restful_rpc => {"access" => "blacklist", "blacklist" => ["9.8.7.6", "9.8.7.5"]}
        @method.call("9.8.7.5").should be_false
      end
      
      it "should allow IPs which are not explicitly specified" do
        mock_component_config_with :restful_rpc => {"access" => "blacklist", "blacklist" => ["10.20.30.40"]}
        @method.call("1.1.1.1").should be_true
      end
      
    end
    
    describe '"everyone" access' do
      it "should return true for any IP given, irrespective of the configuration" do
        ip_addresses = %w[100.200.100.200 0.0.0.0 *.0.0.*]
        ip_addresses.each do |address|
          RESTFUL_RPC.helper_method(:ip_allowed?).call(address).should equal(true)
        end
      end
    end
    
  end

end
