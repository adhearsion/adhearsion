require File.dirname(__FILE__) + "/../test_helper"

context "a new EventSocket" do
  
  include EventSocketTestHelper
  
  test "instantiating a new EventSocket should not instantiate a TCPSocket yet" do
    flexmock(TCPSocket).should_receive(:new).never
    EventSocket.new("localhost", 1234, mock_handler_object)
  end
  
  test "instantiating a new EventSocket with both a block and a handler object" do
    the_following_code {
      EventSocket.new("localhost", 1234, mock_handler_object) {}
    }.should.raise ArgumentError
  end
  
  test "instantiating a new EventSocket with neither a block nor handler object" do
    the_following_code {
      EventSocket.new("localhost", 1234)
    }.should.raise ArgumentError
  end
  
  test "should have an initial state of :new" do
    EventSocket.new("localhost", 1234, mock_handler_object).state.should.equal :new
  end
  
end


context "connecting an EventSocket" do
  
  include EventSocketTestHelper
  
  test "should instantiate a new TCPSocket with the correct host and port" do
    host, port = "google.com", 80
    mock_socket = flexmock "TCPSocket"
    flexmock(TCPSocket).should_receive(:new).once.with(host, port)
    EventSocket.new(host, port, mock_handler_object).connect!
  end
  
  test "should have a state of :connected if TCPSocket instantiates without error" do
    host, port = "google.com", 80
    mock_socket = flexmock "TCPSocket"
    flexmock(TCPSocket).should_receive(:new).once.with(host, port)
    event_socket = EventSocket.new(host, port, mock_handler_object)
    event_socket.connect!
    event_socket.state.should.equal :connected
  end
  
  test "should have a state of :failed when ECONNREFUSED is raised" do
    host, port = "google.com", 80
    mock_socket = flexmock "TCPSocket"
    flexmock(TCPSocket).should_receive(:new).once.with(host, port).and_raise(Errno::ECONNREFUSED)
    event_socket = EventSocket.new(host, port, mock_handler_object)
    event_socket.connect!
    event_socket.state.should.equal :failed
  end
  
  test "should instantiate a new Thread which calls EventSocket#reader_loop" do
    flexmock(TCPSocket).should_receive(:new).once
    flexmock(Thread).should_receive(:new).and_yield
    the_following_code {
      event_socket = EventSocket.new("foo", 123, mock_handler_object)
      flexmock(event_socket).should_receive(:reader_loop).once.and_throw :in_thread_loop
      event_socket.connect!
    }.should.throw :in_thread_loop
  end
  
end

BEGIN {
  module EventSocketTestHelper
    def mock_handler_object
      returning flexmock do |handler|
        flexstub(handler).should_receive(:post_init)
        flexstub(handler).should_receive(:receive_data)
        flexstub(handler).should_receive(:disconnected)
      end
    end
  end
}