##
# EventSocket is a small abstraction of TCPSocket which causes it to behave much like an EventMachine Connection object.
# It acts as a Thread-safe Finite State Machine.
#
# The handler object has these methods called on it:
#  - post_init
#  - disconnected
#  - receive_data
#
# The various states are:
#  - :new
#  - :connected
#  - :stopped
#  - :connection_dropped
#  - 
#
class EventSocket

  MAX_CHUNK_SIZE = 256.kilobytes
  
  def initialize(host, port, handler=nil, &block)
    raise ArgumentError, "Cannot supply both a handler object and a block" if handler && block_given?
    raise ArgumentError, "Must supply either a handler object or a block" if !handler && !block_given?
    
    
    @state_lock = Mutex.new
    @host  = host
    @port  = port
    
    self.state = :new
    
    @handler = handler || new_handler_from_block(&block)
  end
  
  def state
    @state_lock.synchronize { @state }
  end
  
  def connect!
    @socket = TCPSocket.new(@host, @port)
    self.state = :connected
    @handler.post_init
    reader_loop = Thread.new(&method(:reader_loop))
  rescue Errno::ECONNREFUSED
    self.state = :failed
  end
  
  ##
  # 
  #
  def disconnect!
    raise NotImplementedError
  end
  
  protected
  
  def state=(new_state)
    @state_lock.synchronize { @state = new_state }
  end
  
  def reader_loop
    until state.equal? :stopped
      @handler.receive_data @socket.readpartial(MAX_CHUNK_SIZE)
    end
  rescue EOFError
    self.state = :connection_dropped
    @handler.unbind
  end

  def new_handler_from_block(&block)
    raise NotImplementedError
  end

  
end
