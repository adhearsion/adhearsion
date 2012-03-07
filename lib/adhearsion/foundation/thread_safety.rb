require 'thread'

class Object
  def synchronize(&block)
    @mutex ||= Mutex.new
    @mutex.synchronize &block
  end
end

class ThreadSafeArray
  def initialize
    @mutex = Mutex.new
    @array = []
  end

  def method_missing(method, *args, &block)
    @mutex.synchronize do
      @array.send method, *args, &block
    end
  end

  def inspect
    @mutex.synchronize { @array.inspect }
  end

  def to_s
    @mutex.synchronize { @array.to_s }
  end
end
