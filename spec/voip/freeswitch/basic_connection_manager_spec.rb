require 'spec_helper'
require 'adhearsion/voip/freeswitch/basic_connection_manager'

include Adhearsion::VoIP::FreeSwitch

describe "FreeSwitch BasicConnectionManager" do
  attr_reader :manager, :io
  before(:each) do
    @io      = StringIO.new
    @manager = BasicConnectionManager.new io
  end

  it "<<() should add two newlines" do
    manager << "foobar"
    io.string.should == "foobar\n\n"
  end

end

describe "FreeSwitch BasicConnectionManager's header parser" do
  it "YAML-like headers are read properly" do
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