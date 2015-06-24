# encoding: utf-8

module Adhearsion
  module Rayo
    module Component
      class Input < ComponentNode

        include HasHeaders

        NLSML_NAMESPACE = 'http://www.ietf.org/xml/ns/mrcpv2'

        register :input, :input

        # @return [Integer] the amount of time in milliseconds that an input command will wait until considered that a silence becomes a NO-MATCH
        attribute :max_silence, Integer

        # @return [Float] Confidence with which to consider a response acceptable
        attribute :min_confidence, Float

        # @return [Symbol] mode by which to accept input. Can be :voice, :dtmf or :any
        attribute :mode, Symbol, default: :dtmf

        # @return [String] recognizer to use for speech recognition
        attribute :recognizer, String

        # @return [String] language to use for speech recognition
        attribute :language, String

        # @return [String] terminator by which to signal the end of input
        attribute :terminator, String

        # @return [Float] Indicates how sensitive the interpreter should be to loud versus quiet input. Higher values represent greater sensitivity.
        attribute :sensitivity, Float

        # @return [Integer] Indicates the amount of time (in milliseconds) preceding input which may expire before a timeout is triggered.
        attribute :initial_timeout, Integer

        # @return [Integer] Indicates (in the case of DTMF input) the amount of time (in milliseconds) between input digits which may expire before a timeout is triggered.
        attribute :inter_digit_timeout, Integer

        # @return [Integer] Indicates the amount of time during input that recognition will occur before a timeout is triggered.
        attribute :recognition_timeout, Integer

        attribute :grammars, Array, default: []
        def grammars=(others)
          super others.map { |other| Grammar.new(other) }
        end

        ##
        # @param [Hash] other
        # @option other [String] :content_type the document content type
        # @option other [String] :value the grammar doucment
        # @option other [String] :url the url from which to fetch the grammar
        #
        def grammar=(other)
          self.grammars = [other].compact
        end

        def inherit(xml_node)
          grammar_nodes = xml_node.xpath('ns:grammar', ns: self.class.registered_ns)
          self.grammars = grammar_nodes.to_a.map { |grammar_node| Grammar.from_xml(grammar_node)}
          super
        end

        def rayo_attributes
          {
            'max-silence' => max_silence,
            'min-confidence' => min_confidence,
            'mode' => mode,
            'recognizer' => recognizer,
            'language' => language,
            'terminator' => terminator,
            'sensitivity' => sensitivity,
            'initial-timeout' => initial_timeout,
            'inter-digit-timeout' => inter_digit_timeout,
            'recognition-timeout' => recognition_timeout
          }
        end

        def rayo_children(root)
          grammars.each do |grammar|
            grammar.to_rayo(root)
          end
          super
        end

        class Grammar < RayoNode
          register :grammar, :input

          GRXML_CONTENT_TYPE = 'application/srgs+xml'

          attribute :value
          attribute :content_type, String, default: ->(grammar, attribute) { grammar.url ? nil : GRXML_CONTENT_TYPE }
          attribute :url

          def inherit(xml_node)
            self.value = xml_node.content.strip
            super
          end

          def rayo_attributes
            {
              'url' => url,
              'content-type' => content_type
            }
          end

          def rayo_children(root)
            root.cdata value if value
          end

          private

          def grxml?
            content_type == GRXML_CONTENT_TYPE
          end
        end

        class Signal < Event::Complete::Reason
          register :signal, :cpa

          attribute :type, String
          attribute :duration, Integer
          attribute :value, String
        end

        class Complete
          class Match < Event::Complete::Reason
            register :match, :input_complete

            attribute :content_type, String, default: 'application/nlsml+xml'

            attribute :nlsml
            def nlsml=(other)
              doc = case other
              when Nokogiri::XML::Element, Nokogiri::XML::Document
                RubySpeech::NLSML::Document.new(other)
              else
                other
              end
              super doc
            end

            def mode
              nlsml.best_interpretation[:input][:mode]
            end

            def confidence
              nlsml.best_interpretation[:confidence]
            end

            def utterance
              nlsml.best_interpretation[:input][:content]
            end

            def interpretation
              nlsml.best_interpretation[:instance]
            end

            def inherit(xml_node)
              self.nlsml = result_node(xml_node)
              super
            end

            private

            def result_node(xml)
              directly_nested = xml.at_xpath 'ns:result', ns: NLSML_NAMESPACE
              return directly_nested if directly_nested
              document = Nokogiri::XML.parse xml.text, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS
              document.at_xpath 'ns:result', ns: NLSML_NAMESPACE or raise "Couldn't find the NLSML node"
            end
          end

          class NoMatch < Event::Complete::Reason
            register :nomatch, :input_complete
          end

          class NoInput < Event::Complete::Reason
            register :noinput, :input_complete
          end
        end
      end
    end
  end
end
