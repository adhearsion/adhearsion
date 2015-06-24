# encoding: utf-8

module Adhearsion
  class Event
    class Ringing < Event
      register :ringing, :core

      include HasHeaders
    end
  end
end
