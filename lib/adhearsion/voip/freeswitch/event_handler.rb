module Adhearsion
  module VoIP
    module FreeSwitch

      # Subclass this to register a new event handler
      class EventHandler

        @@events = {}
        @@compound_events = {}

        @@connection = nil

        def self.start!(hash=nil)
          login hash if hash
          raise "You must login to the FreeSWITCH EventSocket!" unless @@connection
          loop do
            # debug "Waiting for an event"
            dispatch_event! @@connection.get_header
          end
        end

        def self.dispatch_event!(data)
          #puts "\nHandling an event! #{data.inspect}"
          name = data['Event-Name']
          normal_event = name && @@events[name.underscore.to_sym]
          # puts "THIS IS WHAT I THINK IT MIGHT BE : #{normal_event.inspect} (with #{name.underscore.to_sym.inspect})"
          if normal_event then normal_event.call(data)
          else
            #debug "Trying compound events"
            @@compound_events.each do |(event, block)|
              mini_event = {}
              event.keys.each { |k| mini_event[k] = data[k] }
              block.call(data) if event == mini_event
            end
          end
        rescue => e
          p e
          puts e.backtrace.map { |x| " " * 4 + x }
        end

        protected

        # Can be specified in the subclass
        def self.login(hash)
          debug "Creating a new event connection manager"
          @@connection = InboundConnectionManager.new hash
          debug "Enabling events"
          @@connection.enable_events!
        end

        def self.on(event, &block)
          event = event.underscore.to_sym if event.is_a? String
          (event.kind_of?(Hash) ? @@compound_events : @@events)[event] = block
        end
      end
    end
  end
end