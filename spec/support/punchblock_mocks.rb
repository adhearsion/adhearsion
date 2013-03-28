# encoding: utf-8

def mock_offer(id = nil, headers = {})
  id ||= rand
  mock("Offer: #{id}").tap do |offer|
    offer.stub :call_id => id, :headers_hash => headers
    offer.as_null_object
  end
end
