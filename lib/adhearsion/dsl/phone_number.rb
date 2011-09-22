module Adhearsion
  module DSL
    # The PhoneNumber class is used by one object throughout Adhearsion: the AGI
    # "extension" variable. Using some clevery Ruby hackery, the Extension class allows
    # dialplan writers to use the best of Fixnum and String usage such as
    #
    # - Dialing international numbers
    # - Using a regexp in a case statement for "extension"
    # - Using a numerical range against extension -- e.g. (100...200)
    # - Using the thousands separator
    class PhoneNumber < NumericalString

      # Checks against a pattern identifying US local numbers (i.e numbers
      # without an area code seven digits long)
      def us_local_number?
        to_s =~ Adhearsion::Constants::US_LOCAL_NUMBER
      end

      # Checks against a pattern identifying US domestic numbers.
      def us_national_number?
        to_s =~ Adhearsion::Constants::US_NATIONAL_NUMBER
      end

      # Checks against a pattern identifying an ISN number. See http://freenum.org
      # for more info.
      def isn?
        to_s =~ Adhearsion::Constants::ISN
      end

      # Useful for dialing those 1-800-FUDGEME type numbers with letters in them. Letters
      # in the argument will be converted to their appropriate keypad key.
      def self.from_vanity(str)
        str.gsub(/\W/, '').upcase.tr('A-Z', '22233344455566677778889999')
      end

    end
  end
end
