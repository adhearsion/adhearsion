# encoding: utf-8

module Adhearsion
  ##
  # This manages the list of calls the Adhearsion service receives
  class Calls < Hash
    include Celluloid

    trap_exit :call_died

    def from_offer(offer)
      Call.new(offer).tap do |call|
        self << call
      end
    end

    def <<(call)
      link call
      self[call.id] = call
      current_actor
    end

    def remove_inactive_call(call)
      if call_is_dead?(call) != nil
        call_id = key call
        delete call_id if call_id
      elsif call.respond_to?(:id)
        delete call.id
      else
        delete call
      end
    end

    def with_tag(tag)
      values.find_all do |call|
        call.tagged_with? tag
      end
    end

    private

    def call_is_dead?(call)
      !call.alive?
    rescue NoMethodError
    end

    def call_died(call, reason)
      return unless reason
      catching_standard_errors do
        call_id = key call
        remove_inactive_call call
        PunchblockPlugin.client.execute_command Punchblock::Command::Hangup.new, :async => true, :call_id => call_id
      end
    end
  end
end
