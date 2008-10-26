module Adhearsion
  module VoIP
    module Asterisk
      class ManagerInterface
        module ActionManagerInterfaceConnection

          class << self
    
            ##
            # Simulate a constructor and return a new object extended with this module. Useful for testing.
            #
            # @param [Object] callback_delegate An object on which callbacks such as 
            # @return [Object] An object which responds to the methods defined in this module.
            #
            def new(callback_delegate)
              Module.new do
                include MyProtocol
                define_method(:parser) { blah }
              end
            end
          end

          def receive_data(data)
            puts data
          end

          def post_init
            puts "DONE IT"
            send_data "i seeeeeeee you!"
          end

          def unbind
            puts "wtf?"
          end

        end
      end
    end
  end
end