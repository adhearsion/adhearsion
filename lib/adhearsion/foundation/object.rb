# encoding: utf-8

require 'adhearsion/logging'

class Object
  include Adhearsion::Logging::HasLogger

  undef :pb_logger
  def pb_logger
    logger
  end
end

module Celluloid
  class ActorProxy
    def logger
      Actor.call @mailbox, :logger
    end
  end
end
