require 'spec_helper'

module EventSocketTestHelper
  def mock_handler_object
    flexmock.tap do |handler|
      flexstub(handler).should_receive(:connected)
      flexstub(handler).should_receive(:receive_data)
      flexstub(handler).should_receive(:disconnected)
    end
  end
end

describe "a new EventSocket" do

  include EventSocketTestHelper

  it "instantiating a new EventSocket should not instantiate a TCPSocket yet" do
    flexmock(TCPSocket).should_receive(:new).never
    EventSocket.new("localhost", 1234, mock_handler_object)
  end

  it "instantiating a new EventSocket with both a block and a handler object" do
    the_following_code {
      EventSocket.new("localhost", 1234, mock_handler_object) {}
    }.should raise_error ArgumentError
  end

  it "instantiating a new EventSocket with neither a block nor handler object" do
    the_following_code {
      EventSocket.new("localhost", 1234)
    }.should raise_error ArgumentError
  end

  it "should have an initial state of :new" do
    EventSocket.new("localhost", 1234, mock_handler_object).state.should be :new
  end

  it "the handler created when instantiating the EventSocket with a block" do
    event_socket = EventSocket.new("foo", 123) do |handler|
      handler.receive_data { throw :inside_receive_data }
      handler.disconnected { throw :inside_disconnected}
      handler.connected { throw :inside_connected }
    end
    handler = event_socket.send(:instance_variable_get, :@handler)
    the_following_code {
      handler.send :receive_data, ''
    }.should throw_symbol :inside_receive_data

    %w[disconnected connected].each do |callback|
      the_following_code {
        handler.send callback
      }.should throw_symbol "inside_#{callback}".to_sym
    end
  end

  it 'the handler created when instantiating the EventSocket with a block in which "def" is used to define callbacks' do
    event_socket = EventSocket.new("foo", 123) do |handler|
      def handler.receive_data
        throw :inside_receive_data
      end
      def handler.disconnected
        throw :inside_disconnected
      end
      def handler.connected
        throw :inside_connected
      end
    end
    handler = event_socket.send(:instance_variable_get, :@handler)
    %w[receive_data disconnected connected].each do |callback|
      the_following_code {
        handler.send callback
      }.should throw_symbol "inside_#{callback}".to_sym
    end
  end

end

describe "connecting an EventSocket" do

  include EventSocketTestHelper

  before :each do
    flexmock(Mutex).new_instances.should_receive(:synchronize).zero_or_more_times.and_yield
  end

  it "should instantiate a new TCPSocket with the correct host and port" do
    host, port = "google.com", 80
    mock_socket = flexmock "TCPSocket"
    flexmock(TCPSocket).should_receive(:new).once.with(host, port)
    EventSocket.new(host, port, mock_handler_object).connect!
  end

  it "should have a state of :connected if TCPSocket instantiates without error" do
    host, port = "google.com", 80
    mock_socket = flexmock "TCPSocket"
    flexmock(TCPSocket).should_receive(:new).once.with(host, port)
    event_socket = EventSocket.new(host, port, mock_handler_object)
    event_socket.connect!
    # Avoid race condition in JRuby where state may return nil
    sleep(0.1)
    event_socket.state.should be :connected
  end

  it "should have a state of :failed after ECONNREFUSED is raised" do
    host, port = "google.com", 80
    flexmock(TCPSocket).should_receive(:new).once.with(host, port).and_raise(Errno::ECONNREFUSED)
    event_socket = EventSocket.new(host, port, mock_handler_object)

    the_following_code {
      event_socket.connect!
    }.should raise_error Errno::ECONNREFUSED

    event_socket.state.should be :failed
  end

  it "should instantiate a new Thread which calls EventSocket#reader_loop" do
    flexmock(TCPSocket).should_receive(:new).once
    flexmock(Thread).should_receive(:new).and_yield
    the_following_code {
      event_socket = EventSocket.new("foo", 123, mock_handler_object)
      flexmock(event_socket).should_receive(:reader_loop).once.and_throw :in_thread_loop
      event_socket.connect!
    }.should throw_symbol :in_thread_loop
  end

end

describe "the reader_loop method" do

  include EventSocketTestHelper

  it "should call readpartial() on the TCPSocket and pass that to the receive_data method of handler" do
    mock_handler = flexmock "mock handler object"
    mock_socket  = flexmock "TCPSocket"
    data         = "Jay Phillips " * 25

    mock_handler.should_receive(:connected).and_return
    mock_handler.should_receive(:disconnected).and_return
    mock_handler.should_receive(:receive_data).once.with(data).and_throw :done_testing

    mock_socket.should_receive(:readpartial).once.with(EventSocket::MAX_CHUNK_SIZE).and_return data

    flexmock(TCPSocket).should_receive(:new).once.and_return mock_socket
    flexmock(Thread).should_receive(:new).and_yield

    the_following_code {
      EventSocket.new("foo", 123, mock_handler).connect!
    }.should throw_symbol :done_testing
  end

  it "should set the state to :connection_dropped when an EOFError is raised by readpartial" do
    mock_socket  = flexmock "TCPSocket"
    mock_socket.should_receive(:readpartial).once.and_raise EOFError
    flexmock(TCPSocket).should_receive(:new).once.and_return mock_socket

    flexmock(Thread).should_receive(:new).and_yield

    event_socket = EventSocket.new("foo", 123, mock_handler_object)

    event_socket.connect!
    event_socket.state.should be :connection_dropped
  end

end

describe "the writer_loop method" do

end
