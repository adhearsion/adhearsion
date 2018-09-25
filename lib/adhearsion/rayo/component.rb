# encoding: utf-8

module Adhearsion
  module Rayo
    module Component
      InvalidActionError = Class.new StandardError
    end
  end
end

%w{
  asterisk
  component_node
  input
  output
  prompt
  receive_fax
  record
  send_fax
  stop
  app
}.each { |component| require "adhearsion/rayo/component/#{component}" }
