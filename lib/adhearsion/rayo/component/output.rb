# encoding: utf-8

require 'adhearsion/uri_list'

module Adhearsion
  module Rayo
    module Component
      class Output < ComponentNode
        include HasHeaders

        register :output, :output

        class Document < RayoNode
          register :document, :output

          SSML_CONTENT_TYPE = 'application/ssml+xml'

          # @return [String] the URL from which the fetch the grammar
          attribute :url

          # @return [String] the document content type
          attribute :content_type, String, default: ->(grammar, attribute) { grammar.url ? nil : SSML_CONTENT_TYPE }

          # @return [String, RubySpeech::SSML::Speak, URIList] the document
          attribute :value

          def inherit(xml_node)
            super
            self.value = if ssml?
              RubySpeech::SSML.import xml_node.content
            elsif urilist?
              URIList.import xml_node.content
            else
              xml_node.content
            end
            self
          end

          def rayo_attributes
            {
              'url' => url,
              'content-type' => content_type
            }
          end

          def rayo_children(root)
            root.cdata xml_value
            super
          end

          def size
            if ssml?
              value.children.count
            else
              value.size
            end
          end

          def ssml?
            content_type == SSML_CONTENT_TYPE
          end

          private

          def xml_value
            if ssml?
              value.to_s
            elsif urilist?
              value.to_s
            elsif
              value
            end
          end

          def urilist?
            content_type == 'text/uri-list'
          end
        end

        def inherit(xml_node)
          document_nodes = xml_node.xpath 'ns:document', ns: self.class.registered_ns
          self.render_documents = document_nodes.to_a.map { |node| Document.from_xml node }
          super
        end

        # @return [String] the TTS voice to use
        attribute :voice, String

        # @return [Symbol] input type on which to interrupt output
        attribute :interrupt_on, Symbol

        # @return [Integer] Indicates some offset through which the output should be skipped before rendering begins.
        attribute :start_offset, Integer

        # @return [true, false] Indicates wether or not the component should be started in a paused state to be resumed at a later time.
        attribute :start_paused, Boolean

        # @return [Integer] Indicates the duration of silence that should space repeats of the rendered document.
        attribute :repeat_interval, Integer

        # @return [Integer] Indicates the number of times the output should be played.
        attribute :repeat_times, Integer

        # @return [Integer] Indicates the maximum amount of time for which the output should be allowed to run before being terminated. Includes repeats.
        attribute :max_time, Integer

        # @return [String] the rendering engine requested by the component
        attribute :renderer, String

        def rayo_attributes
          {
            'voice' => voice,
            'interrupt-on' => interrupt_on,
            'start-offset' => start_offset,
            'start-paused' => start_paused,
            'repeat-interval' => repeat_interval,
            'repeat-times' => repeat_times,
            'max-time' => max_time,
            'renderer' => renderer
          }
        end

        def rayo_children(root)
          render_documents.each do |render_document|
            render_document.to_rayo root.parent
          end
          super
        end

        # @return [Document] the document to render
        attribute :render_documents, Array[Document], default: []

        ##
        # @param [Hash] other
        # @option other [String] :content_type the document content type
        # @option other [String] :value the output doucment
        # @option other [String] :url the url from which to fetch the document
        #
        def render_document=(other)
          self.render_documents = [other].compact
        end

        def ssml=(other)
          self.render_documents = [{:value => other}]
        end

        state_machine :state do
          event :paused do
            transition :executing => :paused
          end

          event :resumed do
            transition :paused => :executing
          end
        end

        # Pauses a running Output
        #
        # @return [Command::Output::Pause] an Rayo pause message for the current Output
        #
        # @example
        #    output_obj.pause_action.to_xml
        #
        #    returns:
        #      <pause xmlns="urn:xmpp:rayo:output:1"/>
        def pause_action
          Pause.new :component_id => component_id, :target_call_id => target_call_id
        end

        ##
        # Sends an Rayo pause message for the current Output
        #
        def pause!
          raise InvalidActionError, "Cannot pause a Output that is not executing" unless executing?
          pause_action.tap do |action|
            result = write_action action
            paused! if result
          end
        end

        ##
        # Create an Rayo resume message for the current Output
        #
        # @return [Command::Output::Resume] an Rayo resume message
        #
        # @example
        #    output_obj.resume_action.to_xml
        #
        #    returns:
        #      <resume xmlns="urn:xmpp:rayo:output:1"/>
        def resume_action
          Resume.new :component_id => component_id, :target_call_id => target_call_id
        end

        ##
        # Sends an Rayo resume message for the current Output
        #
        def resume!
          raise InvalidActionError, "Cannot resume a Output that is not paused." unless paused?
          resume_action.tap do |action|
            result = write_action action
            resumed! if result
          end
        end

        class Pause < CommandNode # :nodoc:
          register :pause, :output
        end

        class Resume < CommandNode # :nodoc:
          register :resume, :output
        end

        ##
        # Creates an Rayo seek message for the current Output
        #
        # @return [Command::Output::Seek] a Rayo seek message
        #
        # @example
        #    output_obj.seek_action.to_xml
        #
        #    returns:
        #      <seek xmlns="urn:xmpp:rayo:output:1"/>
        def seek_action(options = {})
          Seek.new({ :component_id => component_id, :target_call_id => target_call_id }.merge(options)).tap do |s|
            s.original_component = self
          end
        end

        ##
        # Sends a Rayo seek message for the current Output
        #
        def seek!(options = {})
          raise InvalidActionError, "Cannot seek an Output that is already seeking." if seeking?
          seek_action(options).tap do |action|
            write_action action
          end
        end

        state_machine :seek_status, :initial => :not_seeking do
          event :seeking do
            transition :not_seeking => :seeking
          end

          event :stopped_seeking do
            transition :seeking => :not_seeking
          end
        end

        class Seek < CommandNode # :nodoc:
          register :seek, :output

          attribute :direction
          attribute :amount

          def request!
            source.seeking!
            super
          end

          def execute!
            source.stopped_seeking!
            super
          end

          def rayo_attributes
            {'direction' => direction, 'amount' => amount}
          end
        end

        ##
        # Creates an Rayo speed up message for the current Output
        #
        # @return [Command::Output::SpeedUp] a Rayo speed up message
        #
        # @example
        #    output_obj.speed_up_action.to_xml
        #
        #    returns:
        #      <speed-up xmlns="urn:xmpp:rayo:output:1"/>
        def speed_up_action
          SpeedUp.new(:component_id => component_id, :target_call_id => target_call_id).tap do |s|
            s.original_component = self
          end
        end

        ##
        # Sends a Rayo speed up message for the current Output
        #
        def speed_up!
          raise InvalidActionError, "Cannot speed up an Output that is already speeding." unless not_speeding?
          speed_up_action.tap do |action|
            write_action action
          end
        end

        ##
        # Creates an Rayo slow down message for the current Output
        #
        # @return [Command::Output::SlowDown] a Rayo slow down message
        #
        # @example
        #    output_obj.slow_down_action.to_xml
        #
        #    returns:
        #      <speed-down xmlns="urn:xmpp:rayo:output:1"/>
        def slow_down_action
          SlowDown.new(:component_id => component_id, :target_call_id => target_call_id).tap do |s|
            s.original_component = self
          end
        end

        ##
        # Sends a Rayo slow down message for the current Output
        #
        def slow_down!
          raise InvalidActionError, "Cannot slow down an Output that is already speeding." unless not_speeding?
          slow_down_action.tap do |action|
            write_action action
          end
        end

        state_machine :speed_status, :initial => :not_speeding do
          event :speeding_up do
            transition :not_speeding => :speeding_up
          end

          event :slowing_down do
            transition :not_speeding => :slowing_down
          end

          event :stopped_speeding do
            transition [:speeding_up, :slowing_down] => :not_speeding
          end
        end

        class SpeedUp < CommandNode # :nodoc:
          register :'speed-up', :output

          def request!
            source.speeding_up!
            super
          end

          def execute!
            source.stopped_speeding!
            super
          end
        end

        class SlowDown < CommandNode # :nodoc:
          register :'speed-down', :output

          def request!
            source.slowing_down!
            super
          end

          def execute!
            source.stopped_speeding!
            super
          end
        end

        ##
        # Creates an Rayo volume up message for the current Output
        #
        # @return [Command::Output::VolumeUp] a Rayo volume up message
        #
        # @example
        #    output_obj.volume_up_action.to_xml
        #
        #    returns:
        #      <volume-up xmlns="urn:xmpp:rayo:output:1"/>
        def volume_up_action
          VolumeUp.new(:component_id => component_id, :target_call_id => target_call_id).tap do |s|
            s.original_component = self
          end
        end

        ##
        # Sends a Rayo volume up message for the current Output
        #
        def volume_up!
          raise InvalidActionError, "Cannot volume up an Output that is already voluming." unless not_voluming?
          volume_up_action.tap do |action|
            write_action action
          end
        end

        ##
        # Creates an Rayo volume down message for the current Output
        #
        # @return [Command::Output::VolumeDown] a Rayo volume down message
        #
        # @example
        #    output_obj.volume_down_action.to_xml
        #
        #    returns:
        #      <volume-down xmlns="urn:xmpp:rayo:output:1"/>
        def volume_down_action
          VolumeDown.new(:component_id => component_id, :target_call_id => target_call_id).tap do |s|
            s.original_component = self
          end
        end

        ##
        # Sends a Rayo volume down message for the current Output
        #
        def volume_down!
          raise InvalidActionError, "Cannot volume down an Output that is already voluming." unless not_voluming?
          volume_down_action.tap do |action|
            write_action action
          end
        end

        state_machine :volume_status, :initial => :not_voluming do
          event :voluming_up do
            transition :not_voluming => :voluming_up
          end

          event :voluming_down do
            transition :not_voluming => :voluming_down
          end

          event :stopped_voluming do
            transition [:voluming_up, :voluming_down] => :not_voluming
          end
        end

        class VolumeUp < CommandNode # :nodoc:
          register :'volume-up', :output

          def request!
            source.voluming_up!
            super
          end

          def execute!
            source.stopped_voluming!
            super
          end
        end

        class VolumeDown < CommandNode # :nodoc:
          register :'volume-down', :output

          def request!
            source.voluming_down!
            super
          end

          def execute!
            source.stopped_voluming!
            super
          end
        end

        class Complete
          class Finish < Event::Complete::Reason
            register :finish, :output_complete
          end

          class MaxTime < Event::Complete::Reason
            register :'max-time', :output_complete
          end
        end
      end
    end
  end
end
