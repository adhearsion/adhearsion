# encoding: utf-8

module Adhearsion
  module HasHeaders
    def self.included(klass)
      klass.attribute :headers, Hash, default: {}
    end

    def headers=(other)
      super(other || {})
    end

    def inherit(xml_node)
      xml_node.xpath('//ns:header', ns: Rayo::RAYO_NAMESPACES[:core]).to_a.each do |header|
        if headers.has_key?(header[:name])
          headers[header[:name]] = [headers[header[:name]]]
          headers[header[:name]] << header[:value]
        else
          headers[header[:name]] = header[:value]
        end
      end
      super
    end

    def rayo_children(root)
      super
      headers.each do |name, value|
        Array(value).each do |v|
          root.header name: name, value: v, xmlns: Rayo::RAYO_NAMESPACES[:core]
        end
      end
    end
  end
end
