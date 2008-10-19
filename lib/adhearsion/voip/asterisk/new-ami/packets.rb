class NormalAmiResponse
  
  attr_accessor :action_id
  attr_accessor :text # For "Response: Follows" sections
  attr_reader :follows_packet
  def initialize(follows_packet=false)
    @follows_packet = follows_packet
    @pairs = {}
  end
  
  def [](arg)
    @pairs[arg]
  end
  
  def []=(key,value)
    # puts "Setting '#{key}' to '#{value}'!"
    @pairs[key] = value
  end
  
end

class Event < NormalAmiResponse
  
  attr_reader :name
  def initialize(name)
    super()
    @name = name.underscore.to_sym
  end
end
