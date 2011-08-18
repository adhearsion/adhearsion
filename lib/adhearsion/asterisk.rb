module Adhearsion
  module Asterisk
    extend ActiveSupport::Autoload

    autoload :Commands

    AGIProtocolError = Class.new StandardError
  end
end
