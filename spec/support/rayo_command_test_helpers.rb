module RayoCommandTestHelpers
  class MockCall
    attr_accessor :variables

    def initialize
      @variables = {}
    end

    def with_command_lock
      yield
    end

    def write_command(command)
      command
    end
  end
end
