# encoding: utf-8

module Adhearsion
  ##
  # This manages the list of calls the Adhearsion service receives
  class Calls < Hash
    include Celluloid

    def from_offer(offer)
      Call.new(offer).tap do |call|
        self << call
      end
    end

    def <<(call)
      self[call.id] = call
      self
    end

    def remove_inactive_call(call)
      delete call.respond_to?(:id) ? call.id : call
    end

    def with_tag(tag)
      find_all do |call|
        call.tagged_with? tag
      end
    end

    def each(&block)
      values.each(&block)
    end
  end
end
