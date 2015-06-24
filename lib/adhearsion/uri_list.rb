# encoding: utf-8

module Adhearsion
  class URIList < SimpleDelegator
    def self.import(string)
      new string.strip.split("\n").map(&:strip)
    end

    def initialize(*list)
      super list.flatten
    end

    def to_s
      join("\n")
    end

    def ==(other)
      self.__getobj__ == other.to_ary
    end
  end
end
