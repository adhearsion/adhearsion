# encoding: utf-8

def mock_offer(id = nil, headers = {})
  id ||= rand
  double("Offer: #{id}").tap do |offer|
    offer.stub :call_id => id, :headers => headers
    offer.as_null_object
  end
end
