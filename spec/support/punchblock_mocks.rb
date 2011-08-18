def mock_offer(id = nil)
  id ||= rand
  flexmock "Offer: #{id}", :call_id => id
end
