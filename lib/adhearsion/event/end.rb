# encoding: utf-8

module Adhearsion
  class Event
    class End < Event
      register :end, :core

      include HasHeaders

      attribute :reason, Symbol
      attribute :platform_code, String

      def inherit(xml_node)
        if reason_node = xml_node.at_xpath('*')
          self.reason = reason_node.name
          self.platform_code = reason_node['platform-code']
        end
        super
      end
    end
  end
end
