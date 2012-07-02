# encoding: utf-8

module Adhearsion::Safely
  def catching_standard_errors(l = logger, &block)
    yield
  rescue StandardError => e
    Adhearsion::Events.trigger :exception, [e, l]
  end
end

class Object
  include Adhearsion::Safely
end
