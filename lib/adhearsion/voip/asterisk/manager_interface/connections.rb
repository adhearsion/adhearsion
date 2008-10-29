module Adhearsion
  module VoIP
    module Asterisk
      class ManagerInterface
        
        ##
        # 
        #
        class ManagerInterfaceActionsConnection < EventMachine::Connection

          def initialize(manager_interface)
            @manager_interface = manager_interface
            @parser = DelegatingAsteriskManagerInterfaceParser.new(manager_interface)
          end

          def receive_data(data)
            @parser << data
          end

          def post_init
            @manager_interface.actions_connection_established
          end

          def unbind
            @manager_interface.actions_connection_disconnected
          end

        end
      
        ##
        # 
        #
        class ManagerInterfaceEventsConnection < EventMachine::Connection
          
          def initialize(manager_interface)
            @parser = DelegatingAsteriskManagerInterfaceParser.new(manager_interface)
          end
          
          def 
          
        end
      end
    end
  end
end