module Adhearsion
  class Dispatcher

    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def start
      Thread.new do
        loop do
          event = client.event_queue.pop
          ahn_log.punchblock.events.notice "#{event.class} event for call: #{event.call_id}"
          if event.is_a?(Punchblock::Rayo::Event::Offer)
            ahn_log.punchblock.events.info "Offer received for call ID #{event.call_id}"
            dispatch_offer event
          else
            # TODO: Dispatch the event to the appropriate call
            ahn_log.punchblock.events.error "Unknown event: #{event.inspect}"
          end
        end
      end
    end

    def dispatch_offer(offer)
      DialPlan::Manager.handle Adhearsion.receive_call_from(offer)
    end
  end
end
