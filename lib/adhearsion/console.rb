require 'pry'

module Adhearsion
  module Console
    include Adhearsion

    class << self
      ##
      # Start the Adhearsion console
      #
      def run
        Pry.prompt = [ proc {|obj, nest_level| "AHN#{'  ' * nest_level}> " },
                       proc {|obj, nest_level| "AHN#{'  ' * nest_level}? " } ]
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
        extend Adhearsion::VoIP::Commands.for('asterisk')
      end
    end
  end
end
