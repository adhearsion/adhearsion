module Adhearsion #:nodoc:
  module VERSION #:nodoc:
    MAJOR = 0   unless defined? MAJOR
    MINOR = 7   unless defined? MINOR
    TINY  = 999 unless defined? TINY

    STRING = [MAJOR, MINOR, TINY].join('.') unless defined? STRING
  end
end