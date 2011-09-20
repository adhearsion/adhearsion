module Adhearsion
  module Punchblock
    module Menu
      extend ActiveSupport::Autoload

      autoload :CalculatedMatch
      autoload :CalculatedMatchCollection

      def menu(*args, &block)
      end

    end
  end
end
