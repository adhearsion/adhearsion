# encoding: utf-8

def mock_offer(id = nil, headers = {})
  id ||= rand
  flexmock("Offer: #{id}", :call_id => id, :headers_hash => headers).tap do |offer|
    offer.should_ignore_missing
  end
end
