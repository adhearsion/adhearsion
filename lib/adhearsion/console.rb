require 'pry'

module Adhearsion
  module Console
    include Adhearsion

    class << self
      ##
      # Start the Adhearsion console
      #
      def run
        Pry.prompt = [
                        proc do |*args|
                          obj, nest_level, pry_instance = args
                          "AHN#{'  ' * nest_level}> "
                        end,
                        proc do |*args|
                          obj, nest_level, pry_instance = args
                          "AHN#{'  ' * nest_level}? "
                        end
                      ]
        Pry.config.command_prefix = "%"
        pry
      end

      def logger
        Adhearsion::Logging
      end

      def calls
        Adhearsion.active_calls
      end

      def use(call)
        unless call.is_a? Adhearsion::Call
          raise ArgumentError unless Adhearsion.active_calls[call]
          call = Adhearsion.active_calls[call]
        end
        Pry.prompt = [ proc { "AHN<#{call.channel}> "},
                       proc { "AHN<#{call.channel}? "}  ]

        # Pause execution of the thread currently controlling the call
        call.with_command_lock do
          CallWrapper.new(call).pry
        end
      end
    end

    class CallWrapper
      attr_accessor :call

      def initialize(call)
        @call = call
        extend Adhearsion::Commands.for('asterisk')
      end
    end
  end
end
