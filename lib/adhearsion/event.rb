# encoding: utf-8

module Adhearsion
  class Event < Rayo::RayoNode
  end
end

%w{
  answered
  asterisk
  complete
  dtmf
  end
  joined
  offer
  ringing
  input_timers_started
  unjoined
  started_speaking
  stopped_speaking
}.each { |e| require "adhearsion/event/#{e}"}
