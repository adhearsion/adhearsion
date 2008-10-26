module Adhearsion
  module VoIP
    module Asterisk
      module Manager
        class AbstractPacket
        end

        class NormalAmiResponse < AbstractPacket
        
          attr_accessor :action_id,
                        :text       # For "Response: Follows" sections
        
          attr_reader :follows_packet
          def initialize(follows_packet=false)
            @follows_packet = follows_packet
            @headers = {}
          end
        
          def headers
            headers.clone
          end
        
          def [](arg)
            @headers[arg]
          end
  
          def []=(key,value)
            @headers[key] = value
          end
  
        end
      
        class ImmediateResponse < AbstractPacket
          attr_reader :message
          def initialize(message)
            @message = message
          end
        end
      
        class Event < NormalAmiResponse
  
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