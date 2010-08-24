module Adhearsion #:nodoc:
  module VERSION #:nodoc:
    MAJOR = 0 unless defined? MAJOR
    MINOR = 8 unless defined? MINOR
    TINY  = 6 unless defined? TINY

    STRING = [MAJOR, MINOR, TINY].join('.') unless defined? STRING
  end

  class PkgVersion
    include Comparable

    attr_reader :major, :minor, :revision

    def initialize(version="")
      @major, @minor, @revision = version.split(".").map(&:to_i)
    end

    def <=>(other)
      return @major <=> other.major if ((@major <=> other.major) != 0)
      return @minor <=> other.minor if ((@minor <=> other.minor) != 0)
      return @revision <=> other.revision if ((@revision <=> other.revision) != 0)
    end

    def self.sort
      self.sort!{|a,b| a <=> b}
    end

    def to_s
      @major.to_s + "." + @minor.to_s + "." + @revision.to_s
    end
  end
end
