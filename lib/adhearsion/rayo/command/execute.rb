require "adhearsion/rayo/command_node"

module Adhearsion
  module Rayo
    module Command
      class Execute < CommandNode
        register :exec, :core

        attribute :api
        attribute :args

        # These fields should be nil for exec commands
        def domain; end
        def target_call_id; end

        def args=(value)
          value.is_a?(String) ? super(value.split(/\s+/)) : super
        end

        def rayo_attributes
          { api:, args: args.join(" ") }
        end
      end
    end
  end
end
