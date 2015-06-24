# encoding: utf-8

module Adhearsion
  class Event
    class Unjoined < Event
      register :unjoined, :core

      # @return [String] the call ID that was unjoined
      attribute :call_uri

      # @return [String] the mixer name that was unjoined
      attribute :mixer_name

      alias :call_id :call_uri
    end
  end
end
