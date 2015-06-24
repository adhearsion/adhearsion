# encoding: utf-8

require 'ruby_jid'

module Adhearsion
  module Rayo
    ##
    # A rayo Ref message. This provides the command ID in response to execution of a command.
    #
    class Ref < RayoNode
      register :ref, :core

      # @return [String] the command URI
      attribute :uri
      def uri=(other)
        super URI(other)
      end

      def scheme
        uri.scheme
      end

      def call_id
        case scheme
        when 'xmpp'
          RubyJID.new(uri.opaque).node
        when nil
          uri.path
        else
          uri.opaque
        end
      end

      def domain
        case scheme
        when 'xmpp'
          RubyJID.new(uri.opaque).domain
        end
      end

      def component_id
        case scheme
        when 'xmpp'
          RubyJID.new(uri.opaque).resource
        else
          call_id
        end
      end

      def rayo_attributes
        {}.tap do |atts|
          atts[:uri] = uri if uri
        end
      end
    end
  end
end
