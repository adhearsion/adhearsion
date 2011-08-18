module Adhearsion
  module DSL
    class Dialplan

      # Serves as a EventCommand proxy for handling EventCommands. Useful
      # if doing any pre-processing.
      #
      # For example, when sending commands over the event socket to FreeSwitch,
      # every command must start with "api", but, when doing an originate, it
      # must begin with an ampersand. These two pre-processors would be developed
      # as separate CommandDispatchers.
      class CommandDispatcher

        attr_reader :factory, :context

        def initialize(factory, context=nil)
          @context = context
          @factory = factory.new context
        end

        def dispatch!(event_command)
          raise NotImplementedError, "Must subclass #{self.class} and override this!"
        end

        def method_missing(name, *args, &block)
          *commands = *@factory.send(name, *args, &block)
          commands.map do |command|
            if command.kind_of? Proc
              instance_eval(&command)
            elsif command.kind_of? EventCommand
              dispatched_command = dispatch! command
              if command.response_block
                while (new_cmd = command.response_block.call(dispatched_command)).kind_of? EventCommand
                  dispatched_command = dispatch! new_cmd
                end
              end
              dispatched_command
            else
              command
            end
          end.last
        rescue ReturnValue => r
          return r.obj
        end

        def return!(obj)
          raise DSL::Dialplan::ReturnValue.new(obj)
        end

        def break!(uuid=@context)
          raise NotImplementedError, "Must subclass #{self.class} and override this!"
        end

        # Takes a Hash and meta_def()'s a method for each key that returns
        # the key's value in the Hash.
        def def_keys!(hash)
          hash.each_pair do |k,v|
            meta_def(k) { v } rescue nil
          end
        end

        def clone
          super.tap do |nemesis|
            instance_variables.each do |iv|
              value = instance_variable_get(iv)
              nemesis.instance_variable_set iv, value.clone if value
            end
          end
        end

      end

    end
  end
end
