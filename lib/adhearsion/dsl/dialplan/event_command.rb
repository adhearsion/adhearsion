module Adhearsion
  module DSL
    class Dialplan
      # Instantiated and returned in every dialplan command
      class EventCommand

        attr_accessor :app, :args, :response_block, :returns, :on_keypress

        def initialize(app, *args, &block)
          @hash = args.pop if args.last.kind_of?(Hash)
          @app, @args = app, args

          if @hash
            @returns = @hash[:returns] || :raw
            @on_keypress = @hash[:on_keypress]
          end

          @response_block = block if block_given?
        end

        def on_keypress(&block)
          block_given? ? @on_keypress = block : @on_keypress
        end

        def on_break(&block)
          block_given? ? @on_break = block : @on_break
        end

      end
    end
  end
end
