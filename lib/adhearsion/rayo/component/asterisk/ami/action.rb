# encoding: utf-8

module Adhearsion
  module Rayo
    module Component
      module Asterisk
        module AMI
          class Action < ComponentNode
            register :action, :ami

            attribute :name
            attribute :params, Hash, default: {}

            def inherit(xml_node)
              xml_node.xpath('//ns:param', ns: self.class.registered_ns).to_a.each do |param|
                params[param[:name]] = param[:value]
              end
              super
            end

            def rayo_attributes
              {'name' => name}
            end

            def rayo_children(root)
              super
              params.each do |name, value|
                root.param name: name, value: value
              end
            end

            class Complete
              class Success < Event::Complete::Reason
                register :success, :ami_complete

                attribute :message
                attribute :text_body
                attribute :headers, Hash, default: {}

                alias :attributes :headers

                def inherit(xml_node)
                  message_node = xml_node.at_xpath 'ns:message', ns: self.class.registered_ns
                  self.message = message_node.text if message_node

                  text_body_node = xml_node.at_xpath 'ns:text-body', ns: self.class.registered_ns
                  self.text_body = text_body_node.text if text_body_node

                  xml_node.xpath('//ns:attribute', ns: self.class.registered_ns).to_a.each do |attribute|
                    headers[attribute[:name]] = attribute[:value]
                  end
                  super
                end
              end
            end
          end
        end
      end
    end
  end
end
