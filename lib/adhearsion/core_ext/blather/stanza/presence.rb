# encoding: utf-8

module Blather
  class Stanza
    class Presence
      alias :event :rayo_node

      def rayo_event?
        event.is_a? Adhearsion::Event
      end
    end
  end
end
