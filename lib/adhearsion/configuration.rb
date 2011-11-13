module Adhearsion

  class Configuration < OpenStruct

    def initialize
      super
      block_given? and yield self
    end

    def add_configuration_for(name, &block)
      self.send("#{name}=".to_sym, Adhearsion::Configuration.new(&block))
    end

    def [] value
      self.value if self.respond_to? value.to_sym
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

    def method_missing(name, *args, &blk)
      if name.to_s =~ /^(.*)_enabled\?$/
        self.send($1) ? true : false
      else
        super
      end
    end
  end
end



