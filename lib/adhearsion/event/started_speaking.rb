# encoding: utf-8

require 'adhearsion/event/active_speaker'

module Adhearsion
  class Event
    class StartedSpeaking < Event
      register :'started-speaking', :core

      include ActiveSpeaker
    end
  end
end
