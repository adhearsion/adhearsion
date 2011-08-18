module Adhearsion
  module Commands
    def self.for(platform_name)
      Adhearsion.const_get(platform_name.to_s.classify).const_get("Commands")
    end
  end
end
