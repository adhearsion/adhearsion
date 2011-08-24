module Adhearsion
  class Dispatcher

    attr_accessor :event_queue

    def initialize(event_queue)
      @event_queue = event_queue
    end

    def start
      Thread.new do
        loop do
          dispatch_event event_queue.pop rescue nil
        end
      end
    end

    def dispatch_event(event)
      if event.is_a?(Punchblock::Event::Offer)
        ahn_log.dispatcher.info "Offer received for call ID #{event.call_id}"
        Thread.new do
          dispatch_offer event
        end
      else
        if event.responds_to?(:call_id) && event.call_id
          dispatch_call_event event
        else
          ahn_log.dispatcher.error "Unknown event: #{event.inspect}"
        end
      end
    end

    def dispatch_offer(offer)
      DialPlan::Manager.handle Adhearsion.receive_call_from(offer)
    end

    def dispatch_call_event(event)
      if call = Adhearsion.active_calls.find(event.call_id)
        ahn_log.dispatcher.notice "Event received for call #{call.id}: #{event.inspect}"
        call << event
      else
        ahn_log.dispatcher.error "Event received for inactive call #{event.call_id}: #{event.inspect}"
      end
    end
  end
end
