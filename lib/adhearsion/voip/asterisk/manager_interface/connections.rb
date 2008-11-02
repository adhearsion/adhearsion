module Adhearsion
  module VoIP
    module Asterisk
      module Manager
        class ManagerInterface
        
          module ManagerInterfaceActionsConnection
        
            class << self
              def new(manager_interface)
                parser = DelegatingAsteriskManagerInterfaceParser.new manager_interface, \
                    :message_received => :action_message_received,
                    :error_received   => :action_error_received
                Module.new do
                  include ManagerInterfaceActionsConnection
                  define_method(:manager_interface) { manager_interface }
                  define_method(:parser) { parser }
                end
              end
            end
            
            def receive_data(data)
              parser << data
            end
            
            def post_init
              manager_interface.send(:login, self)
            end
            
            def unbind
              manager_interface.actions_connection_disconnected
            end
            
          end
          
          module ManagerInterfaceEventsConnection
          
            class << self
              def new(manager_interface)
                parser = DelegatingAsteriskManagerInterfaceParser.new manager_interface, \
                    :message_received => :event_message_received,
                    :error_received   => :event_error_received
                Module.new do
                  include ManagerInterfaceEventsConnection
                  define_method(:manager_interface) { manager_interface }
                  define_method(:parser) { parser }
                end
              end
            end
            
            def receive_data(data)
              puts "RECEIVED DATA ON EVNETS #{data}"
              parser << data
            end
            
            def post_init
              manager_interface.send(:login, self)
            end
            
            def unbind
              manager_interface.events_connection_disconnected
            end
            
          end
        end
      end
    end
  end
end