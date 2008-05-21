require 'thread'

module Adhearsion
  module Events
    class DeferredEventGroup < ThreadGroup
      attr_reader :name
      def initialize(name)
        raise ArgumentError, 'Name must be a symbol' unless name.is_a? Symbol
        @name = name
      end
    end
  end
end