# encoding: utf-8

module Adhearsion #:nodoc:

  class PkgVersion
    include Comparable

    attr_reader :major, :minor, :revision

    def initialize(version = nil)
      version ||= ""
      @major, @minor, @revision, @patchlevel = version.split(".", 4).map(&:to_i)
      @major = 0 unless @major
    end

    def <=>(other)
      return @major     <=> other.major     unless (@major <=> other.major) == 0
      return @minor     <=> other.minor     unless (@minor <=> other.minor) == 0
      return @revision  <=> other.revision  unless (@revision <=> other.revision) == 0
      return 0
    end

    def self.sort
      self.sort! { |a,b| a <=> b }
    end

    def to_s
      "#{@major}.#{@minor}.#{@revision}"
    end
  end
  VERSION = '2.0.0.rc2'
end
