require 'thread'
require File.join(File.dirname(__FILE__), "ami.rb")

class EventHandler
  
  @@patterns = {}
  @@pattern_lock = Mutex.new
  
  PredefinedPatterns = {
    :conference_created => {"TODO" => "TODO"}
  }
  
  class << self
    
    def clear!
      with_lock { @@patterns.clear }
    end
    
    def registered_patterns
      with_lock { return @@patterns.clone }
    end
    
    def handle_event(event)
      with_lock {
        @@patterns.each_pair do |pattern, block|
          case pattern
            when :any: block.call(event)
            when String
              block.call(event) if pattern == event["Action"]
            when Hash
              block.call(event) if pattern.inject { |boolean,(key,value)| event[key.to_s] == value.to_s ? true : break}
          end
        end
      }
    end
    
    def pattern_for_symbol(symbol)
      PredefinedPatterns[symbol]
    end
    
    protected

    def on(pattern, &block)
      raise unless block_given?
      if pattern.kind_of?(Symbol) && pattern != :any
        pattern = pattern_for_symbol pattern
        raise "Unrecognized pattern #{pattern.inspect}" unless pattern
      end
      with_lock { @@patterns[pattern] = block }
    end
    
    private
    
    def with_lock(&block)
      @@pattern_lock.synchronize(&block)
    end
    
  end
end
