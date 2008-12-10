require 'rack'
require 'json'

# Don't you love regular expressions? Matches only 0-255 octets. Use "*" for an octet wildcard.
VALID_IP_ADDRESS = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|\*)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|\*)$/


def ip_allowed?(ip)
  raise ArgumentError, "#{ip.inspect} is not a valid IP address!" unless ip.kind_of?(String) && ip =~ VALID_IP_ADDRESS
  
  octets = ip.split "."
  
  case COMPONENTS.restful_rpc
    when "everyone"
      true
    when "whitelist"
      whitelist = COMPONENTS.restful_rpc["whitelist"]
      whitelist.find do |pattern|
        pattern_octets = pattern.split "."
        # Traverse both arrays in parallel
        octets.zip(pattern_octets).map do |octet, octet_pattern|
          octet_pattern == "*" ? true : (octet == octet_pattern)
        end == [true, true, true, true]
      end
    when "blacklist"
      
    else
      raise ConfigurationError, ""
  end
  
  true
end

def serve(env)
  # TODO: set the content-type to 
  [200, {}, env["REQUEST_PATH"]]
end

initialization do
  
  api = method :serve

  protection = Rack::Auth::Basic.new(api) do |username, password|
    password == "secret!"
  end

  protection.realm = "Adhearsion API"

  # pretty_api = Rack::ShowStatus.new Rack::ShowExceptions.new(protection)

  Rack::Handler::Mongrel.run pretty_api, :Port => 5000
  
end
