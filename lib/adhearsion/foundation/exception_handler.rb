class Object
  def catching_standard_errors(&block)
    begin
      yield
    rescue StandardError => e
      Adhearsion::Events.trigger :exception, e
    end
  end
end
