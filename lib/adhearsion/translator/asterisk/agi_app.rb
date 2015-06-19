# encoding: utf-8

module Adhearsion
  module Translator
    class Asterisk
      class AGIApp
        def initialize(app, *args)
          @app, @args = app, args
        end

        def execute(call)
          call.execute_agi_command "EXEC #{@app}", @args.join(',')
        end
      end
    end
  end
end
