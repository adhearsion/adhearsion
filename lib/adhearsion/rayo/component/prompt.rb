# encoding: utf-8

module Adhearsion
  module Rayo
    module Component
      class Prompt < ComponentNode
        register :prompt, :prompt

        attribute :barge_in, Boolean
        attribute :output, Output
        attribute :input, Input

        ##
        # Create a prompt command
        #
        # @param [Output] output
        # @param [Input] input
        # @param [Hash] options
        # @option options [true, false, optional] :barge_in Indicates wether or not the input should interrupt then output
        #
        # @return [Component::Prompt] a formatted Rayo prompt command
        #
        def initialize(output = nil, input = nil, options = {})
          super options
          self.output = output
          self.input  = input
        end

        def inherit(xml_node)
          input_node = xml_node.at_xpath('ns:input', ns: Input.registered_ns)
          self.input = Input.from_xml input_node if input_node

          output_node = xml_node.at_xpath('ns:output', ns: Output.registered_ns)
          self.output = Output.from_xml output_node if output_node

          super
        end

        def rayo_attributes
          {
            'barge-in' => barge_in
          }
        end

        def rayo_children(root)
          input.to_rayo(root) if input
          output.to_rayo(root) if output
          super
        end
      end
    end
  end
end
