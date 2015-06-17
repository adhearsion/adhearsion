# encoding: utf-8

module Adhearsion
  module Rayo
    module Command
    end
  end
end

%w{
  accept
  answer
  dial
  hangup
  join
  mute
  redirect
  reject
  unjoin
  unmute
}.each { |event| require "adhearsion/rayo/command/#{event}" }
