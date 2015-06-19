# encoding: utf-8

module Adhearsion
  class Event
    class DTMF < Event
      register :dtmf, :core

      attribute :signal
    end
  end
end
