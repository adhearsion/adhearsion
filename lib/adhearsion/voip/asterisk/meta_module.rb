module UniversalAccess
  def self.>>(sym)
    MetaModule.new sym
  end
  
  class MetaModule < Module
    def initialize(sym)
      @name = sym
    end
    
    def self.included(klass)
      # TODO: Add a proxy object around klass to the UnversalAccess thing.
    end
  end
end