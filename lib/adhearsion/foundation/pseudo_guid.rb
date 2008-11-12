module PseudoGuidGenerator
  ##
  # Generates a new 128-bit Globally Unique Identifier. It is a "pseudo" in that it does not adhere to the RFC which mandates
  # that a certain section be reserved for a fragment of the NIC MAC address.
  def new_guid(separator="-")
    [8,4,4,4,12].map { |segment_length| String.random(segment_length) }.join(separator)
  end
end

include PseudoGuidGenerator