# encoding: utf-8

module Adhearsion
  module Rayo
    BASE_RAYO_NAMESPACE     = 'urn:xmpp:rayo'
    BASE_ASTERISK_NAMESPACE = 'urn:xmpp:rayo:asterisk'
    RAYO_VERSION            = '1'
    RAYO_NAMESPACES         = {:core => [BASE_RAYO_NAMESPACE, RAYO_VERSION].compact.join(':')}

    [:ext, :record, :output, :input, :prompt, :cpa, :fax].each do |ns|
      RAYO_NAMESPACES[ns] = [BASE_RAYO_NAMESPACE, ns.to_s, RAYO_VERSION].compact.join(':')
      RAYO_NAMESPACES[:"#{ns}_complete"] = [BASE_RAYO_NAMESPACE, ns.to_s, 'complete', RAYO_VERSION].compact.join(':')
    end

    [:agi, :ami].each do |ns|
      RAYO_NAMESPACES[ns] = [BASE_ASTERISK_NAMESPACE, ns.to_s, RAYO_VERSION].compact.join(':')
      RAYO_NAMESPACES[:"#{ns}_complete"] = [BASE_ASTERISK_NAMESPACE, ns.to_s, 'complete', RAYO_VERSION].compact.join(':')
    end
  end
end

require 'adhearsion/rayo/client'
require 'adhearsion/rayo/connection'
require 'adhearsion/rayo/command'
require 'adhearsion/rayo/command_node'
require 'adhearsion/rayo/component'
require 'adhearsion/rayo/disconnected_error'
require 'adhearsion/rayo/initializer'
require 'adhearsion/rayo/rayo_node'
require 'adhearsion/rayo/ref'
require 'adhearsion/rayo/response'
