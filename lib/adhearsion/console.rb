require 'pry'

module Adhearsion
  module Console
    include Adhearsion

    class << self
      ##
      # Start the Adhearsion console
      #
      def run
        Pry.prompt = [ proc {|obj, nest_level| puts obj.inspect; puts nest_level.inspect; "AHN#{'  ' * nest_level}> " },
                       proc {|obj, nest_level| puts obj.inspect; puts nest_level.inspect; "AHN#{'  ' * nest_level}? " } ]
        pry
      end

      def logger
        Adhearsion::Logging
      end

      def calls
        Adhearsion.active_calls
      end

      def use(call)
        Pry.prompt = [ proc { "AHN<#{call.channel}> "},
                       proc { "AHN<#{call.channel}? "}  ]
        CallWrapper.new(call).pry
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
