module PseudoGuidGenerator
  def gui
    [8,4,4,4,12].map { |segment_length| String.random(segment_length) }.join('-')
  end
end

include PseudoGuidGenerator