# encoding: utf-8

require 'adhearsion/event'

module Adhearsion
  class Event
    class Complete < Event
      register :complete, :ext

      attribute :reason

      attribute :recording

      attribute :fax
      attribute :fax_metadata, Hash, default: {}

      def inherit(xml_node)
        if reason_node = xml_node.at_xpath('*')
          self.reason = Adhearsion::Rayo::RayoNode.from_xml(reason_node).tap do |reason|
            reason.target_call_id = target_call_id
            reason.component_id = component_id
          end
        end

        if recording_node = xml_node.at_xpath('//ns:recording', ns: Rayo::RAYO_NAMESPACES[:record_complete])
          self.recording = Adhearsion::Rayo::RayoNode.from_xml(recording_node).tap do |recording|
            recording.target_call_id = target_call_id
            recording.component_id = component_id
          end
        end

        if fax_node = xml_node.at_xpath('//ns:fax', ns: Rayo::RAYO_NAMESPACES[:fax_complete])
          self.fax = Adhearsion::Rayo::RayoNode.from_xml(fax_node).tap do |fax|
            fax.target_call_id = target_call_id
            fax.component_id = component_id
          end
        end

        xml_node.xpath('//ns:metadata', ns: Rayo::RAYO_NAMESPACES[:fax_complete]).each do |md|
          fax_metadata[md['name']] = md['value']
        end

        super
      end

      class Reason < Event
        attribute :name, Symbol, default: ->(node,_) { node.class.registered_name.to_sym }

        def inherit(xml_node)
          self.name = xml_node.name.to_sym
          super
        end
      end

      class Stop < Reason
        register :stop, :ext_complete
      end

      class Hangup < Reason
        register :hangup, :ext_complete
      end

      class Error < Reason
        register :error, :ext_complete

        attribute :details

        def inherit(xml_node)
          self.details = xml_node.text.strip
          super
        end
      end
    end
  end
end
