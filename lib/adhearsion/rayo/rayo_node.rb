# encoding: utf-8

require 'active_support/core_ext/class/attribute'
require 'virtus'

require 'adhearsion/rayo'

module Adhearsion
  module Rayo
    class RayoNode
      include Virtus.model

      @@registrations = {}

      class_attribute :registered_ns, :registered_name

      attribute :target_call_id
      attribute :target_mixer_name
      attribute :component_id
      attribute :source_uri
      attribute :domain
      attribute :transport
      attribute :timestamp, DateTime, default: ->(*) { DateTime.now }

      attr_accessor :connection, :client, :original_component

      # Register a new stanza class to a name and/or namespace
      #
      # This registers a namespace that is used when looking
      # up the class name of the object to instantiate when a new
      # stanza is received
      #
      # @param [#to_s] name the name of the node
      # @param [String, nil] ns the namespace the node belongs to
      def self.register(name, ns = nil)
        self.registered_name = name.to_s
        self.registered_ns = ns.is_a?(Symbol) ? RAYO_NAMESPACES[ns] : ns
        @@registrations[[self.registered_name, self.registered_ns]] = self
      end

      # Find the class to use given the name and namespace of a stanza
      #
      # @param [#to_s] name the name to lookup
      # @param [String, nil] xmlns the namespace the node belongs to
      # @return [Class, nil] the class appropriate for the name/ns combination
      def self.class_from_registration(name, ns = nil)
        @@registrations[[name.to_s, ns]]
      end

      # Import an XML::Node to the appropriate class
      #
      # Looks up the class the node should be then creates it based on the
      # elements of the XML::Node
      # @param [XML::Node] node the node to import
      # @return the appropriate object based on the node name and namespace
      def self.from_xml(node, call_id = nil, component_id = nil, uri = nil, timestamp = nil)
        ns = (node.namespace.href if node.namespace)
        klass = class_from_registration(node.name, ns)
        if klass && klass != self
          klass.from_xml node, call_id, component_id
        else
          new.inherit node
        end.tap do |event|
          event.target_call_id = call_id
          event.component_id = component_id
          event.source_uri = uri
          event.timestamp = timestamp if timestamp
        end
      end

      def inherit(xml_node)
        xml_node.attributes.each do |key, attr_node|
          setter_method = "#{key.gsub('-', '_')}="
          send setter_method, xml_node[key] if respond_to?(setter_method)
        end
        self
      end

      def inspect
        "#<#{self.class} #{to_hash.map { |k, v| "#{k}=#{v.inspect}" }.compact * ', '}>"
      end

      def ==(o)
        o.is_a?(self.class) && self.comparable_attributes == o.comparable_attributes
      end

      ##
      # @return [RayoNode] the original command issued that lead to this event
      #
      def source
        @source ||= client.find_component_by_uri source_uri if client && source_uri
        @source ||= original_component
      end

      def rayo_attributes
        {}
      end

      def rayo_children(root)
      end

      def to_rayo(parent = nil)
        parent = parent.parent if parent.is_a?(Nokogiri::XML::Builder)
        Nokogiri::XML::Builder.with(parent) do |xml|
          xml.send("#{registered_name}_",
            {xmlns: registered_ns}.merge(rayo_attributes.delete_if { |k,v| v.nil? })) do |root|
            rayo_children root
          end
        end.doc.root
      end

      def to_xml
        to_rayo.to_xml
      end

      alias :to_s :inspect

    protected

      def comparable_attributes
        to_hash.tap do |hash|
          hash.delete :timestamp
        end
      end
    end
  end
end
