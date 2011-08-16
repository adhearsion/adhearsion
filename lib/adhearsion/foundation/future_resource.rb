require "thread"

class FutureResource
  def initialize
    @resource_lock          = Monitor.new
    @resource_value_blocker = @resource_lock.new_cond
  end

  def set_yet?
    @resource_lock.synchronize { defined? @resource }
  end

  def resource
    @resource_lock.synchronize do
      @resource_value_blocker.wait unless defined? @resource
      @resource
    end
  end

  def resource=(resource)
    @resource_lock.synchronize do
      raise ResourceAlreadySetException if defined? @resource
      @resource = resource
      @resource_value_blocker.broadcast
      @resource_value_blocker = nil # Don't really need it anymore.
    end
  end

  class ResourceAlreadySetException < StandardError
    def initialize
      super "Cannot set this resource twice!"
    end
  end
end
