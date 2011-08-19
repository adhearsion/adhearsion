module Adhearsion
  class Dispatcher

    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def start
      Thread.new do
        loop do
          dispatch_event client.event_queue.pop rescue nil
        end
      end
    end

    def dispatch_event(event)
      if event.is_a?(Punchblock::Rayo::Event::Offer)
        ahn_log.punchblock.events.info "Offer received for call ID #{event.call_id}"
        dispatch_offer event
      else
        if event.responds_to?(:call_id) && event.call_id
          dispatch_call_event event
        else
          ahn_log.punchblock.events.error "Unknown event: #{event.inspect}"
        end
      end
    end

    def dispatch_offer(offer)
      DialPlan::Manager.handle Adhearsion.receive_call_from(offer)
    end

    def dispatch_call_event(event)
      if call = Adhearsion.active_calls.find(event.call_id)
        ahn_log.punchblock.events.notice "Event received for call #{call.id}: #{event.inspect}"
        call << event
      else
        ahn_log.punchblock.events.error "Event received for inactive call #{event.call_id}: #{event.inspect}"
      end
    end
  end
end
