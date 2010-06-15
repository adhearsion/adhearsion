module Adhearsion
  module VoIP
    module Asterisk
      module Manager

        ##
        # Higher level abstraction of the Asterisk Manager Interface.
        #
        class SuperManager

          def initialize
            raise NotImplementedError
          end

        end
      end
    end
  end
end