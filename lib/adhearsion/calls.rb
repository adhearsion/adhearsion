require 'thread'

module Adhearsion
  ##
  # This manages the list of calls the Adhearsion service receives
  class Calls
    attr_reader :semaphore, :calls

    def initialize
      @semaphore = Monitor.new
      @calls     = {}
    end

    def <<(call)
      atomically { calls[call.id] = call }
    end

    def any?
      atomically { !calls.empty? }
    end

    def size
      atomically { calls.size }
    end

    def remove_inactive_call(call)
      atomically { calls.delete call.id }
    end

    # Searches all active calls by their id
    def find(id)
      atomically { calls[id] }
    end
    alias :[] :find

    def clear!
      atomically { calls.clear }
    end

    def with_tag(tag)
      atomically do
        calls.inject([]) do |calls_with_tag,(key,call)|
          call.tagged_with?(tag) ? calls_with_tag << call : calls_with_tag
        end
      end
    end

    def each(&block)
      atomically { calls.values.each &block }
    end

    def each_pair
      calls.each_pair { |id, call| yield id, call }
    end

    def to_a
      calls.values
    end

    def to_h
      calls
    end

    def method_missing(m, *args)
      atomically { calls.send m.to_sym, *args }
    end

    private

    def atomically(&block)
      semaphore.synchronize(&block)
    end

  end
end
