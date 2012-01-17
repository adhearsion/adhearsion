module Adhearsion
  class DialplanController < CallController
    attr_accessor :dialplan

    def run
      instance_exec &dialplan
    end
  end
end
