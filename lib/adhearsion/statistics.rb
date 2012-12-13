# encoding: utf-8

module Adhearsion
  class Statistics
    include Celluloid

    exclusive

    def initialize
      @calls_dialed = @calls_offered = @calls_routed = @calls_rejected = 0
    end

    def dump
      Dump.new timestamp: Time.now, call_counts: dump_call_counts
    end

    def register_call_dialed
      @calls_dialed += 1
    end

    def register_call_offered
      @calls_offered += 1
    end

    def register_call_routed
      @calls_routed += 1
    end

    def register_call_rejected
      @calls_rejected += 1
    end

    private

    def dump_call_counts
      {dialed: @calls_dialed, offered: @calls_offered, routed: @calls_routed, rejected: @calls_rejected, active: Adhearsion.active_calls.count}
    end

    class Dump
      include Comparable

      attr_reader :timestamp, :call_counts

      def initialize(opts = {})
        @timestamp = opts[:timestamp]
        @call_counts = opts[:call_counts]
      end

      def <=>(other)
        timestamp <=> other.timestamp
      end
    end
  end
end
