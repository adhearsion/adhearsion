module Adhearsion
  # Please help adjust these if they may be inaccurate!
  module Constants
    US_LOCAL_NUMBER = /^[1-9]\d{6}$/
    US_NATIONAL_NUMBER = /^1?[1-9]\d{2}[1-9]\d{6}$/
    ISN = /^\d+\*\d+$/ # See http://freenum.org
    SIP_URI = /^sip:[\w\._%+-]+@[\w\.-]+\.[a-zA-Z]{2,4}$/

    # Type of Number definitions given over PRI. Taken from the Q.931-ITU spec, page 68.
    Q931_TYPE_OF_NUMBER = Hash.new(:unknown).merge 0b001 => :international,
                                                   0b010 => :national,
                                                   0b011 => :network_specific,
                                                   0b100 => :subscriber,
                                                   0b110 => :abbreviated_number
  end

  include Constants
end
