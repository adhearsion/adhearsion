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