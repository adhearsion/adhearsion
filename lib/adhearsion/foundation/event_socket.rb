##
# EventSocket is a small abstraction of TCPSocket which causes it to behave much like an EventMachine Connection object for
# the sake of better testability. The EventMachine Connection paradigm (as well as other networking libraries such as the
# Objective-C HTTP library) uses callbacks to signal different stages of a socket's lifecycle.
#
# A handler can be registered in one of two ways: through registrations on an object yielded by the constructor or
# pre-defined on the object given as a constructor parameter. Below is an example definition which uses the block way:
#
#   EventSocket.new do |handler|
#     def handler.receive_data(data)
#       # Do something here
#     end
#     def handler.disconnected
#       # Do something here
#     end
#     def handler.connected
#       # Do something here
#     end
#   end
#
# Note: this is also a valid way of defining block callbacks:
#
#   EventSocket.new do |handler|
#     handler.receive_data { |data| do_something }
#     handler.disconnected { do_something }
#     handler.connected    { do_something }
#   end
#
# and here is an example of using a handler object:
#
#   class MyCallbackHandler
#     def receive_data(data) end
#     def connected() end
#     def disconnected() end
#   end
#   EventSocket.new(MyCallbackHandler.new)
#
# If you wish to ask the EventSocket what state it is in, you can call the Thread-safe EventSocket#state method. The
# supported states are:
#
#  - :new
#  - :connected
#  - :stopped
#  - :connection_dropped
#
# Note: the EventSocket's state will be changed before these callbacks are executed. For example, if your "connected"
# callback queried its own EventSocket for its state, it will have already transitioned to the connected() state.
#
# Warning: If an exception occurs in your EventSocket callbacks, they will be "eaten" and never bubbled up the call stack.
# You should always wrap your callbacks in a begin/rescue clause and handle exceptions explicitly.
#
require "thread"
require "socket"

class EventSocket

  class << self

    ##
    # Creates and returns a connected EventSocket instance.
    #
    def connect(*args, &block)
      instance = new(*args, &block)
      instance.connect!
      instance
    end
  end

  MAX_CHUNK_SIZE = 256 * 1024

  def initialize(host, port, handler=nil, &block)
    raise ArgumentError, "Cannot supply both a handler object and a block" if handler && block_given?
    raise ArgumentError, "Must supply either a handler object or a block" if !handler && !block_given?

    @state_lock = Mutex.new
    @host  = host
    @port  = port

    @state = :new
    @handler = handler || new_handler_from_block(&block)
  end

  def state
    @state_lock.synchronize { @state }
  end

  def connect!
    @state_lock.synchronize do
      if @state.equal? :connected
        raise ConnectionError, "Already connected!"
      else
        @socket = TCPSocket.new(@host, @port)
        @state  = :connected
      end
    end
    @handler.connected rescue nil
    @reader_thread = spawn_reader_thread
    self
  rescue => error
    @state = :failed
    raise error
  end

  ##
  # Thread-safe implementation of write.
  #
  # @param [String] data Data to write
  #
  def send_data(data)
    # Note: TCPSocket#write is intrinsically Thread-safe
    @socket.write data
  rescue
    connection_dropped!
  end
    ##
  # Disconnects this EventSocket and sets the state to :stopped
  #
  def disconnect!
    @state_lock.synchronize do
      @socket.close rescue nil
      @state = :stopped
    end
  end

  ##
  # Joins the Thread which reads data off the socket.
  #
  def join
    @state_lock.synchronize do
      if @state.equal? :connected
        @reader_thread.join
      else
        nil
      end
    end
  end

  def receive_data(data)
    @handler.receive_data(data)
  end

  protected

  def connection_dropped!
    @state_lock.synchronize do
      unless @state.equal? :connection_dropped
        @socket.close rescue nil
        @state = :connection_dropped
        @handler.disconnected
      end
    end
  end

  def spawn_reader_thread
    Thread.new(&method(:reader_loop))
  end

  def reader_loop
    until state.equal? :stopped
      data = @socket.readpartial(MAX_CHUNK_SIZE)
      @handler.receive_data data
    end
  rescue EOFError
    connection_dropped!
  end

  def new_handler_from_block(&handler_block)
    handler = Object.new
    handler.metaclass.send :attr_accessor, :set_callbacks
    handler.metaclass.send :public, :set_callbacks, :set_callbacks=
    handler.set_callbacks = {:receive_data => false, :disconnected => false, :connected => false }

    def handler.receive_data(&block)
      self.metaclass.send(:remove_method, :receive_data)
      self.metaclass.send(:define_method, :receive_data) { |data| block.call data }
      set_callbacks[:receive_data] = true
    end
    def handler.connected(&block)
      self.metaclass.send(:remove_method, :connected)
      self.metaclass.send(:define_method, :connected) { block.call }
      set_callbacks[:connected] = true
    end
    def handler.disconnected(&block)
      self.metaclass.send(:remove_method, :disconnected)
      self.metaclass.send(:define_method, :disconnected) { block.call }
      set_callbacks[:disconnected] = true
    end

    def handler.singleton_method_added(name)
      set_callbacks[name.to_sym] = true
    end

    yield handler

    handler.set_callbacks.each_pair do |callback_name,was_set|
      handler.send(callback_name) {} unless was_set
    end

    handler

  end

  class ConnectionError < StandardError; end

end
