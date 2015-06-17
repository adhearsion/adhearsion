# encoding: utf-8

module Adhearsion
  class Event
    class Joined < Event
      register :joined, :core

      # @return [String] the call ID that was joined
      attribute :call_uri

      # @return [String] the mixer name that was joined
      attribute :mixer_name

      alias :call_id :call_uri
    end
  end
end
