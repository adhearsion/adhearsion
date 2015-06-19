# encoding: utf-8

require 'adhearsion/rayo/component/component_node'
require 'adhearsion/event/complete'

module Adhearsion
  module Rayo
    module Component
      module Asterisk
        module AGI
          class Command < ComponentNode
            register :command, :agi

            attribute :name
            attribute :params, Array, default: []

            def inherit(xml_node)
              xml_node.xpath('//ns:param', ns: self.class.registered_ns).to_a.each do |param|
                params << param[:value]
              end
              super
            end

            class Complete
              class Success < Event::Complete::Reason
                register :success, :agi_complete

                attribute :code, Integer
                attribute :result, Integer
                attribute :data

                def inherit(xml_node)
                  [:code, :result, :data].each do |attr|
                    node = xml_node.at_xpath "ns:#{attr}", ns: self.class.registered_ns
                    self.send "#{attr}=", node.text if node
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
