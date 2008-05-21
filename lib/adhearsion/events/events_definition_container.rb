module Adhearsion
  module Events
    class EventsDefinitionContainer
      class << self
        def from(filename)
          returning new do |instance|
            instance.instance_eval(File.read(filename), filename)
          end
        end
      end
    end
  end
end