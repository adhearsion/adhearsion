# encoding: utf-8

module Adhearsion
  class Event
    class Answered < Event
      register :answered, :core

      include HasHeaders
    end
  end
end
