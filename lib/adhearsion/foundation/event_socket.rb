##
# EventSocket is a small abstraction of TCPSocket which causes it to behave much like an EventMachine Connection object.
# It acts as a Thread-safe Finite State Machine.
#
# The handler object has these methods called on it:
#  - connected
#  - disconnected
#  - receive_data
#
# Note: the EventSocket's state will be changed before these callbacks are executed.
#
# The various states are:
#  - :new
#  - :connected
#  - :stopped
#  - :connection_dropped
#
# When instantiating this EventSocket with a block, you register callbacks by defining the methods on the yielded object.
# For example:
#   EventSocket.new do |handler|
#     def handler.receive_data(data)
#       # Do something here
#     end
#     def handler.disconnected(data)
#       # Do something here
#     end
#     def handler.connected(data)
#       # Do something here
#     end
#   end
#
require "thread"
require "socket"

class EventSocket

  class << self
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
    @handler.connected
    @reader_thread = spawn_reader_thread
  rescue => error
    @state = :failed
    raise error
  end
  
  ##
  # Thread-safe implementation of write.
  #
  # @param [String] data Data to write
  #
  def write(data)
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
  
  protected
  
  def connection_dropped!
    puts "got conneciton dropped"
    @state_lock.synchronize do
      unless @state.equal? :connection_dropped
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
  rescue => e
    puts "SOME OTHER ERROR?"
  end

  def new_handler_from_block(&handler_block)
    handler = Object.new
    handler.metaclass.send :attr_accessor, :set_callbacks
    handler.set_callbacks = {:receive_data => false, :disconnected => false, :connected => false }
    
    def handler.receive_data(&block)
      self.metaclass.send :remove_method, :receive_data
      self.metaclass.send :define_method, :receive_data, &block
      set_callbacks[:receive_data] = true
    end
    def handler.connected(&block)
      self.metaclass.send :remove_method, :connected
      self.metaclass.send :define_method, :connected, &block
      set_callbacks[:connected] = true
    end
    def handler.disconnected(&block)
      self.metaclass.send :remove_method, :disconnected
      self.metaclass.send :define_method, :disconnected, &block
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

  class ConnectionError < Exception; end
  
end
