require File.dirname(__FILE__) + "/../../test_helper"
require 'adhearsion/voip/freeswitch/basic_connection_manager'

include Adhearsion::VoIP::FreeSwitch

context "FreeSwitch BasicConnectionManager" do
  attr_reader :manager, :io
  setup do
    @io      = StringIO.new
    @manager = BasicConnectionManager.new io
  end
  
  test "<<() should add two newlines" do
    manager << "foobar"
    io.string.should == "foobar\n\n"
  end
  
end

context "FreeSwitch BasicConnectionManager's header parser" do
  test "YAML-like headers are read properly" do
    header = {
      "Foo-Bar"                  => "bar",
      "Qaz-Monkey-Charlie-Zebra" => "qwerty"
    }
    
    string_header = header.inject("") do |string, (key, value)|
      string + "#{key}: #{value}\n"
    end
    
    string_header << "\n"
    
    manager = BasicConnectionManager.new StringIO.new(string_header)
    manager.get_raw_header.should == string_header.strip
    
    manager = BasicConnectionManager.new StringIO.new(string_header)
    manager.get_header.should == header
  end
end