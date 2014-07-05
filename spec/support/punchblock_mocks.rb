# encoding: utf-8

def mock_offer(id = nil, headers = {})
  id ||= rand
  double("Offer: #{id}").tap do |offer|
    allow(offer).to receive_messages :call_id => id, :headers => headers
    offer.as_null_object
  end
end
