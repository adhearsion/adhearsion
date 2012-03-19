# encoding: utf-8

require 'adhearsion/logging'

module PBLoggerOverride
  def pb_logger
    logger
  end
end

class Object
  include PBLoggerOverride

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
    return true if method_id == Adhearsion::Logging::METHOD

    super
  end
end
