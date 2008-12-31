require 'rubygems'
require 'rest_client'
require 'json'

# You must have the "rest-client" and "json" gems installed for this file to work.

class RESTfulAdhearsion
  
  DEFAULT_OPTIONS = {
    # Note: :user and :password are non-existent by default
    :host => "localhost",
    :port => "5000",
    :path_nesting => "/"
  }
  
  def initialize(options={})
    @options = DEFAULT_OPTIONS.merge options
    
    @path_nesting = @options.delete :path_nesting
    @host = @options.delete :host
    @port = @options.delete :port
    
    @url_beginning = "http://#{@host}:#{@port}#{@path_nesting}"
  end
  
  def method_missing(method_name, *args)
    JSON.parse RestClient::Resource.new(@url_beginning + method_name.to_s, @options).post(args.to_json)
  end
  
end

Adhearsion = RESTfulAdhearsion.new :host => "localhost", :port => 5000, :user => "jicksta", :password => "roflcopterz"

# ### Sample component code. Try doing "ahn create component testing123" and pasting this code in.
#
# methods_for :rpc do
#   def i_like_hashes(options={})
#     options.has_key?(:foo)
#   end
#   def i_like_arrays(*args)
#     args.reverse
#   end
# end

# Note: everything returned will be wrapped in an Array

p Adhearsion.i_like_hashes(:foo => "bar")
p Adhearsion.i_like_arrays(1,2,3,4,5)
