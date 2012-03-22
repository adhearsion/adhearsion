# encoding: utf-8

class Object
  def catching_standard_errors(l = logger, &block)
    begin
      yield
    rescue StandardError => e
      Adhearsion::Events.trigger :exception, [e, l]
    end
  end
end
