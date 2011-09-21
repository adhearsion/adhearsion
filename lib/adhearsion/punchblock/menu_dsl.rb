module Adhearsion
  module Punchblock
    module MenuDSL
      extend ActiveSupport::Autoload

      autoload :CalculatedMatch
      autoload :CalculatedMatchCollection
      autoload :MatchCalculator
      autoload :FixnumMatchCalculator
      autoload :RangeMatchCalculator
      autoload :StringMatchCalculator
      autoload :MenuBuilder

    end
  end
end
