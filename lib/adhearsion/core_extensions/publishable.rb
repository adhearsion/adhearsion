module Adhearsion
  class DrbDoor
    
    include Singleton
    
    def add(interface, name, meth)
      @interfaces ||= {}
      @interfaces[interface] ||= returning(Object.new) { |obj| obj.metaclass.send(:attr_accessor, :__methods) }
      obj = @interfaces[interface]
      obj.__methods ||= {}
      obj.__methods[name] = meth
      obj.instance_eval <<-STR
        def #{name}(*args, &block)
          begin
            __methods["#{name}"].call(*args, &block)
          rescue => exception
            raise RuntimeError, exception.message
          end
        end
      STR
    end

    def method_missing(name, *args, &block)
      return Module.const_get(name) if (?A..?Z).include? name.to_s[0]
      super unless @interfaces && @interfaces.has_key?(name.to_s)
      @interfaces[name.to_s]
    end
  end

  module Publishable
    def self.included(base)
      base.send(:alias_method_chain, :initialize, :publishable)
      base.extend(ClassMethods)
    end

    def initialize_with_publishable(*args, &block)
      initialize_without_publishable(*args, &block)
      self.class.published_instance_methods.each do |(sym, interface)|
        DrbDoor.instance.add(interface, sym.to_s, self.method(sym))
      end
    end

    module ClassMethods
      attr_reader :interface
      attr_reader :published_instance_methods
    
      def publish(options={}, &block)
        @interface = options.delete(:through).to_s || self.to_s
        begin
          @capture = true
          yield
        ensure
          @capture = false
        end
      end

      def method_added(sym)
        return if not @capture
        if sym.to_s !~ /method_added/
          @published_instance_methods ||= []
          @published_instance_methods << [sym, @interface]
        end
      end

      def singleton_method_added(sym)
        return if not @capture
        if sym.to_s !~ /method_added/
          DrbDoor.instance.add(@interface, sym.to_s, method(sym.to_s))
        end
      end
    end
  end
end