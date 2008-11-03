##
# Implementation of a Thread-safe Hash. Works by delegating methods to a Hash behind-the-scenes after obtaining an exclusive # lock. Use exactly as you would a normal Hash.
#
class SynchronizedHash
  
  def self.atomically_delegate(method_name)
    class_eval(<<-RUBY, __FILE__, __LINE__)
      def #{method_name}(*args, &block)
        @lock.synchronize do
          @delegate.send(#{method_name.inspect}, *args, &block)
        end
      end
    RUBY
  end
  
  # Hash-related methods
  
  atomically_delegate :[]
  atomically_delegate :[]=
  atomically_delegate :all?
  atomically_delegate :any?
  atomically_delegate :clear
  atomically_delegate :collect
  atomically_delegate :default
  atomically_delegate :default=
  atomically_delegate :delete
  atomically_delegate :delete_if
  atomically_delegate :detect
  atomically_delegate :each
  atomically_delegate :each_key
  atomically_delegate :each_pair
  atomically_delegate :each_value
  atomically_delegate :each_with_index
  atomically_delegate :empty?
  atomically_delegate :entries
  atomically_delegate :fetch
  atomically_delegate :find
  atomically_delegate :find_all
  atomically_delegate :grep
  atomically_delegate :has_key?
  atomically_delegate :has_value?
  atomically_delegate :include?
  atomically_delegate :index
  atomically_delegate :indexes
  atomically_delegate :indices
  atomically_delegate :inject
  atomically_delegate :invert
  atomically_delegate :key?
  atomically_delegate :keys
  atomically_delegate :length
  atomically_delegate :map
  atomically_delegate :max
  atomically_delegate :member?
  atomically_delegate :merge
  atomically_delegate :merge!
  atomically_delegate :min
  atomically_delegate :partition
  atomically_delegate :rehash
  atomically_delegate :reject
  atomically_delegate :reject!
  atomically_delegate :replace
  atomically_delegate :select
  atomically_delegate :shift
  atomically_delegate :size
  atomically_delegate :sort
  atomically_delegate :sort_by
  atomically_delegate :store
  atomically_delegate :to_hash
  atomically_delegate :update
  atomically_delegate :value?
  atomically_delegate :values
  atomically_delegate :values_at
  atomically_delegate :zip
  
  # Object-related methods
  
  atomically_delegate :inspect
  atomically_delegate :to_s
  atomically_delegate :marshal_dump
  
  def initialize(*args, &block)
    @delegate = Hash.new(*args, &block)
    @lock     = Mutex.new
  end
  
  ##
  # If you need to do many operations atomically (a la transaction), you can call this method and access the yielded Hash
  # which can be safely modified for the duration of your block.
  #
  # @yield [Hash] the Hash on which you can safely operate during your block.
  #
  def with_lock(&block)
    @lock.synchronize { yield @delegate }
  end
  
end