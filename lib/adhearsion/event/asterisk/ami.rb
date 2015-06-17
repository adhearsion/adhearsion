# encoding: utf-8

module Adhearsion
  class Event
    module Asterisk
      class AMI < Event
        register :event, :ami

        attribute :name
        attribute :headers, Hash, default: {}

        alias :attributes :headers

        def inherit(xml_node)
          xml_node.xpath('//ns:attribute', ns: self.class.registered_ns).to_a.each do |attribute|
            headers[attribute[:name]] = attribute[:value]
          end
          super
        end

        def rayo_attributes
          {'name' => name}
        end

        def rayo_children(root)
          super
          headers.each do |name, value|
            root.attribute name: name, value: value
          end
        end
      end
    end
  end
end
