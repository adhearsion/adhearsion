module Adhearsion
  module Punchblock
    extend ActiveSupport::Autoload

    autoload :Commands
    autoload :Menu

    include ::Punchblock
  end
end
