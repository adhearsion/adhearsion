module Adhearsion
  module VoIP
    module Asterisk
      module Manager

        class ManagerInterfaceResponse
        
          attr_accessor :action_id,
                        :text_body  # For "Response: Follows" sections
          
          def initialize
            @headers = {}
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
      
        class ManagerInterfaceError < Exception
          
          attr_accessor :message
          def initialize
            @headers = {}
          end
          
          def [](key)
            @headers[key]
          end
          
          def []=(key,value)
            @headers[key] = value
          end
          
        end
        
        class ImmediateResponse
          attr_reader :message
          def initialize(message)
            @message = message
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