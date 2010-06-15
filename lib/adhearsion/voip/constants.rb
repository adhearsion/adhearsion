# Adhearsion, open source collaboration framework
# Copyright (C) 2006,2007,2008 Jay Phillips
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

module Adhearsion
  module VoIP

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
end