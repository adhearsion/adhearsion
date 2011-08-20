def mock_offer(id = nil)
  id ||= rand
  flexmock("Offer: #{id}", :call_id => id).tap do |offer|
    offer.should_ignore_missing
  end
end
