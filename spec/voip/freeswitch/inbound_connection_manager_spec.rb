require 'spec_helper'
require 'adhearsion/voip/freeswitch/inbound_connection_manager'
include Adhearsion::VoIP::FreeSwitch

describe "A FreeSwitch InboundConnectionManager" do

  it "authenticatating with the given password" do
    manager = InboundConnectionManager.new io_mock
    manager.login password
  end

  it "a hash is accepted when creating a new InboundConnectionManager" do
    host, port = "myhost.mydomain", 31337

    flexmock(TCPSocket).should_receive(:new).once.with(host, port).and_return io_mock

    InboundConnectionManager.new :host => host, :port => port, :pass => password
  end

  it "an IO is accepted when creating a new InboundConnectionManager"

  private
    def io_mock
      @io_mock ||=
        begin
          io_mock = StringIO.new
          flexmock(io_mock) do |io|
            io.should_receive(:write).with("auth #{password}\n\n")
            io.should_receive(:gets).and_return "connection: kthnx\n",
              "\n", "login: +OK\n", "\n"
          end
          io_mock
        end
    end

    def password
      "supersecret"
    end
end