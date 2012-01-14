require 'adhearsion/logging'

class Object
  def pb_logger
    logger
  end

  def logger_id
    self
  end

  def method_missing(method_id, *arguments, &block)
    if method_id == Adhearsion::Logging::METHOD
      self.class.send :define_method, method_id do
        Logging.logger[logger_id]
      end
      Logging.logger[logger_id]
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
