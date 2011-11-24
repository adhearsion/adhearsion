require 'adhearsion/logging'

# Monkey patch Object to support the #tap method.
# This method is present in Ruby 1.8.7 and later.
unless Object.respond_to?(:tap)
  class Object
    def tap
      yield self
      self
    end
  end
end

class Object
  def pb_logger
    logger
  end

  def method_missing(method_id, *arguments, &block)
    if method_id == Adhearsion::Logging::METHOD
      self.class.send :define_method, method_id do
        Logging.logger[self]
      end
      Logging.logger[self]
    else
      super
    end
  end

  def respond_to?(method_id, include_private = false)
    if method_id == Adhearsion::Logging::METHOD
      true
    else
      super
    end
  end
end
