# encoding: utf-8

require 'adhearsion/event/active_speaker'

module Adhearsion
  class Event
    class StoppedSpeaking < Event
      register :'stopped-speaking', :core

      include ActiveSpeaker
    end
  end
end
