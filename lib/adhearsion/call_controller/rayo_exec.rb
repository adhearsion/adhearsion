# encoding: utf-8

require 'countdownlatch'

module Adhearsion
  class CallController
    module RayoExec
      def rayo_exec(api, args)
        raise NotImplementedError, 'This method is only supported on Rayo' unless Adhearsion.config.core.type == :xmpp
        block_until_resumed
        write_and_await_response Adhearsion::Rayo::Command::Exec.new(api: api, args: args)
      end

      def rayo_app(app, args)
        raise NotImplementedError, 'This method is only supported on Rayo' unless Adhearsion.config.core.type == :xmpp
        execute_component_and_await_completion Adhearsion::Rayo::Component::App.new(app: app, args: args)
      end
    end
  end
end

