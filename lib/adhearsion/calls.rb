# encoding: utf-8

require 'thread'

module Adhearsion
  ##
  # This manages the list of calls the Adhearsion service receives
  class Calls
    def initialize
      @mutex = ::Monitor.new
      @calls = {}
      restart_supervisor
    end

    def <<(call)
      @supervisor.link call
      @mutex.synchronize do
        self[call.id] = call
        by_uri[call.uri] = call

        # Create indexes to avoid scanning @calls or @by_uri
        call_id_by_object_id[call.object_id] = call.id if call.respond_to?(:id)
        uri_by_object_id[call.object_id] = call.uri if call.respond_to?(:uri)
      end
      self
    end

    def remove_inactive_call(call)
      if call_is_dead?(call)
        delete call_id_by_object_id[call.object_id]
        remove_call_uri call
        remove_from_indices call
      elsif call.respond_to?(:id)
        delete call.id
        remove_call_uri call
        remove_from_indices call
      else
        call_actor = delete call
        remove_call_uri call_actor
        remove_from_indices call_actor
      end
    end

    def with_tag(tag)
      values.find_all do |call|
        begin
          call.tagged_with? tag
        rescue Call::ExpiredError
          false
        end
      end
    end

    def with_uri(uri)
      by_uri[uri]
    end

    def restart_supervisor
      @supervisor.terminate if @supervisor
      @supervisor = Supervisor.new self
    end

    private

    def by_uri
      @by_uri ||= {}
    end

    def call_id_by_object_id
      @call_id_by_object_id ||= {}
    end

    def uri_by_object_id
      @uri_by_object_id ||= {}
    end

    def remove_call_uri(call)
      by_uri.delete uri_by_object_id[call.object_id]
    end

    def remove_from_indices(call)
      uri_by_object_id.delete call.object_id
      call_id_by_object_id.delete call.object_id
    end

    def call_is_dead?(call)
      !call.alive?
    rescue ::NoMethodError
      false
    end

    def delete(call_id)
      @calls.delete call_id
    end

    def method_missing(method, *args, &block)
      @mutex.synchronize do
        @calls.send method, *args, &block
      end
    end

    class Supervisor
      include Celluloid

      trap_exit :call_died

      def initialize(collection)
        @collection = collection
      end

      def call_died(call, reason)
        catching_standard_errors do
          call_id = @collection.key call
          @collection.remove_inactive_call call
          return unless reason
          Adhearsion::Events.trigger :exception, reason
          logger.error { "Call #{call_id} terminated abnormally due to #{reason}. Forcing hangup." }
          Adhearsion.client.execute_command Adhearsion::Rayo::Command::Hangup.new, :async => true, :call_id => call_id
        end
      end
    end
  end
end
