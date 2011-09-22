module Adhearsion
  module DSL
    extend ActiveSupport::Autoload

    autoload :DialingDSL
    autoload :Dialplan
    autoload :NumericalString
    autoload :PhoneNumber
  end
end
