module Adhearsion
  module VoIP
    module Asterisk
      module Manager


        ##
        # This is the object containing a response from Asterisk.
        #
        # Note: not all responses have an ActionID!
        #
        class ManagerInterfaceResponse

          class << self
            def from_immediate_response(text)
              new.tap do |instance|
                instance.text_body = text
              end
            end
          end

          attr_accessor :action,
                        :action_id,
                        :text_body  # For "Response: Follows" sections
          attr_reader   :events

          def initialize
            @headers = HashWithIndifferentAccess.new
          end

          def has_text_body?
            !! @text_body
          end

          def headers
            @headers.clone
          end

          def [](arg)
            @headers[arg]
          end

          def []=(key,value)
            @headers[key] = value
          end

        end

        class ManagerInterfaceError < StandardError

          attr_accessor :message
          def initialize
            @headers = HashWithIndifferentAccess.new
          end

          def [](key)
            @headers[key]
          end

          def []=(key,value)
            @headers[key] = value
          end

        end

        class ManagerInterfaceEvent < ManagerInterfaceResponse

          attr_reader :name
          def initialize(name)
            super()
            @name = name
          end

        end
      end
    end
  end
end