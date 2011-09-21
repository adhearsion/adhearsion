module Adhearsion
  module Punchblock
    module Menu
      extend ActiveSupport::Autoload

      autoload :CalculatedMatch
      autoload :CalculatedMatchCollection
      autoload :MatchCalculator
      autoload :FixnumMatchCalculator
      autoload :RangeMatchCalculator
      autoload :StringMatchCalculator
      autoload :MenuBuilder

      def menu(*args, &block)
      end

    end
  end
end
