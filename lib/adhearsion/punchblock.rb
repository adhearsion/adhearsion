module Adhearsion
  module Punchblock
    extend ActiveSupport::Autoload

    autoload :Commands
    autoload :MenuDSL

    include ::Punchblock
  end
end
