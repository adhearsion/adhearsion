# encoding: utf-8

require 'adhearsion/rayo/command_node'
require 'adhearsion/has_headers'
require 'adhearsion/rayo/command/join'

module Adhearsion
  module Rayo
    module Command
      class Dial < CommandNode
        register :dial, :core

        include HasHeaders

        # @return [String] destination to dial
        attribute :to

        # @return [String] the caller ID
        attribute :from

        # @return [String] the requested URI for the resulting call
        attribute :uri

        # @return [Integer] timeout in milliseconds
        attribute :timeout, Integer

        # @return [Join] the nested join
        attribute :join, Join

        def inherit(xml_node)
          if join_element = xml_node.at_xpath('ns:join', ns: Join.registered_ns)
            self.join = Join.from_xml(join_element)
          end
          super
        end

        def rayo_attributes
          {to: to, from: from, uri: uri, timeout: timeout}
        end

        def rayo_children(root)
          join.to_rayo(root.parent) if join
          super
        end

        def response=(other)
          if other.is_a?(Ref)
            @transport = other.scheme
            @target_call_id = other.call_id
            @domain = other.domain
          end
          super
        end
      end
    end
  end
end
