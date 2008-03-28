module PseudoUuidGenerator
  def uuid
    returning Array.new(32) { String.random_char } do |string|
      [8, 13, 18, 23].each do |index|
        string.insert index, '-'
      end
    end.join
  end
end

include PseudoUuidGenerator