class Object
  def metaclass
    class << self
      self
    end
  end

  def meta_eval(&block)
    metaclass.instance_eval &block
  end

  def meta_def(name, &block)
    meta_eval do
      define_method name, &block
    end
  end
end
