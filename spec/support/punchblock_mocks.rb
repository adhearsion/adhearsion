# encoding: utf-8

def mock_offer(id = nil, headers = {})
  id ||= rand
  double("Offer: #{id}").tap do |offer|
    allow(offer).to receive_messages :call_id => id, :headers => headers
    offer.as_null_object
  end
end

module HasMockCallbackConnection
  def self.included(test_case)
    test_case.let(:connection) do
      double('Connection').tap do |mc|
        allow(mc).to receive :handle_event do |event|
          original_command.add_event event
        end
      end
    end
  end
end
