class DrbDoor
  include Singleton
  def add(interface, name, meth)
    @interfaces ||= {}
    @interfaces[interface] ||= returning(Object.new) do |obj|
      obj.class.instance_eval do
        attr_accessor :__methods
      end
    end
    obj = @interfaces[interface]
    obj.class.instance_eval { define_method(name) { __methods[name].call } }
    obj.__methods ||= {}
    obj.__methods[name] = meth
  end
  
  def method_missing(name, *args, &block)
    return Module.const_get(name) if (?A..?Z).include? name.to_s[0]
    return super unless @interfaces and @interfaces.keys.include? name.to_s
    @interfaces[name.to_s]
  end
end

module Publishable
  class UnpublishableMethod < RuntimeError; end
    
  def self.included(base)
    base.extend(ClassMethods)
    base.metaclass.send(:alias_method_chain, :singleton_method_added, :publishable)
    base.metaclass.send(:alias_method_chain, :method_added, :publishable)
  end

  module ClassMethods
    attr_reader :interface
    def publish(options={}, &block)
      @interface = options.delete(:through).to_s || self.to_s
      begin
        @capture = true
        yield
      ensure
        @capture = false
      end
    end
    def method_added_with_publishable(sym)
      method_added_without_publishable(sym)
      return if @capture == false
      raise UnpublishableMethod, "Cannot publish instance method " + sym.to_s
    end
    def singleton_method_added_with_publishable(sym)
      singleton_method_added_without_publishable(sym)
      return if @capture == false
      if sym.to_s !~ /method_added/
        DrbDoor.instance.add(@interface, sym.to_s, method(sym.to_s))
      end
    end
  end
end
