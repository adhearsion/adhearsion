class Thread
  class << self
    
    # Syntactically sugar Thread.current since it's used so much.
    #
    # Allows:
    #   Thread.me.extend DSL::Dialplan::ThreadMixin
    #   Thread.my.call.io = io
    
    alias me current
    alias my current
  end
end