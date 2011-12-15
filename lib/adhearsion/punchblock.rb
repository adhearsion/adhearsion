module Adhearsion
  module Punchblock
    extend ActiveSupport::Autoload

    autoload :MenuDSL

    include ::Punchblock
  end
end
