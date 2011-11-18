module Adhearsion

  class BasicConfiguration < OpenStruct

    def initialize params = {}
      super params
      block_given? and yield self
    end

    def add_configuration_for(name, &block)
      self.send("#{name}=".to_sym, Adhearsion::BasicConfiguration.new(&block))
    end

    def [] value
      return self.value if self.respond_to? value.to_sym
    end

    def configure(name = nil, &block)
      config_var = case value
      when Nil
        self
      else
        @values[name.to_sym]
      end
      yield config_var if block_given? 
    end

    # Return the defined configuration keys
    def values
      self.instance_variable_get(:@table).keys.dup
    end

    def length
      values.length
    end

    # Get a configuration value using a Hash syntax
    # Adhearsion.config.foo = "bar"
    # Adhearsion.config[:foo] => "bar"
    def [](value)
      self.send(value)
    end

    # Set a configuration value using a Hash syntax
    # Adhearsion.config[:foo] = "bar"
    # Adhearsion.config.foo => "bar"
    def []=(key, value)
      self.send("#{key.to_sym}=", value)
    end

    def to_s
      values.inject([]) do|k,v|
        k << "#{v}: #{self.send(v)}"
      end.join("\n")
    end

    def method_missing(name, *args, &blk)
      # Validate if there is configuration for a specific var
      # Adhearsion.config.foo_enabled? => false
      # Adhearsion.config.foo = "bar"
      # Adhearsion.config.foo_enabled? => true
      if name.to_s =~ /^(.*)_enabled\?$/
        self.send($1) ? true : false
      else
        super
      end
    end
  end
end



