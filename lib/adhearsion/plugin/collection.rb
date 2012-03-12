# encoding: utf-8

require 'tsort'

module Adhearsion
  class Plugin
    class Collection < Array
      include TSort

      alias :tsort_each_node :each

      def tsort_each_child(child, &block)
        select { |i| i.before == child.name || i.name == child.after }.each(&block)
      end

      def +(other)
        Collection.new(to_a + other.to_a)
      end
    end
  end
end
