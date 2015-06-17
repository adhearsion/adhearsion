# encoding: utf-8

module Adhearsion
  module Rayo
    module Component
      class SendFax < ComponentNode
        register :sendfax, :fax

        class FaxDocument < RayoNode
          register :document, :fax

          attribute :url, String
          attribute :identity, String
          attribute :header, String
          attribute :pages, String

          def inherit(xml_node)
            super
            if pages = xml_node[:pages]
              self.pages = pages.split(',').map { |p| p.include?('-') ? Range.new(*p.split('-').map(&:to_i)) : p.to_i }
            end
            self
          end

          def rayo_attributes
            {
              'url'      => url,
              'identity' => identity,
              'header'   => header,
              'pages'    => rayo_pages
            }
          end

        private

          def rayo_pages
            pages ? pages.map { |p| p.is_a?(Range) ? "#{p.min}-#{p.max}" : p }.join(',') : nil
          end
        end

        def inherit(xml_node)
          document_nodes = xml_node.xpath 'ns:document', ns: self.class.registered_ns
          self.render_documents = document_nodes.to_a.map { |node| FaxDocument.from_xml node }

          super
       end

        def rayo_children(root)
          render_documents.each do |render_document|
            render_document.to_rayo root.parent
          end
          super
        end

        # @return [Document] the document to render
        attribute :render_documents, Array[FaxDocument], default: []

        def render_document=(other)
          self.render_documents = [other].compact
        end
      end
    end
  end
end
