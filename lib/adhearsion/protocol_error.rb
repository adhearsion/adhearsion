# encoding: utf-8

require 'adhearsion/error'

module Adhearsion
  ##
  # This exception may be raised if a transport error is detected.
  class ProtocolError < Error
    attr_accessor :name, :text, :call_id, :component_id

    def setup(name = nil, text = nil, call_id = nil, component_id = nil)
      @name, @text, @call_id, @component_id = name, text, call_id, component_id
      self
    end

    def to_s
      "#<#{self.class}: name=#{name.inspect} text=#{text.inspect} call_id=#{call_id.inspect} component_id=#{component_id.inspect}>"
    end
    alias :inspect :to_s

    def eql?(other)
      other.is_a?(self.class) && [:name, :text, :call_id, :component_id].all? { |f| self.__send__(f) == other.__send__(f) }
    end
    alias :== :eql?
  end
end
