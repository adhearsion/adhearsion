# encoding: utf-8

module Adhearsion
  module MenuDSL
    extend ActiveSupport::Autoload

    autoload :Exceptions
    autoload :CalculatedMatch
    autoload :CalculatedMatchCollection
    autoload :MatchCalculator
    autoload :FixnumMatchCalculator
    autoload :RangeMatchCalculator
    autoload :StringMatchCalculator
    autoload :MenuBuilder
    autoload :Menu
  end
end
