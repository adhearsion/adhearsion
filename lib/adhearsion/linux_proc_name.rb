# encoding: utf-8

module Adhearsion

  # https://gist.github.com/1350729
  #
  # Eric Lindvall <eric@5stops.com>
  # 
  # Update the process name for the process you're running in.
  #
  # $0    => updates proc name for ps command
  # prctl => updates proc name for lsof, top, killall commands (...)
  #
  # prctl does not work on OS X
  #
  module LinuxProcName
    # Set process name
    PR_SET_NAME = 15

    class << self
      attr_accessor :error

      def set_proc_name(name)
        $0 = name # process name in ps command
        if error
          logger.warn error
          return false
        end
        return false unless LibC.respond_to?(:prctl)

        # The name can be up to 16 bytes long, and should be null-terminated if
        # it contains fewer bytes.
        name = name.slice(0, 16)
        ptr = FFI::MemoryPointer.from_string(name)
        LibC.prctl(PR_SET_NAME, ptr.address, 0, 0) # process name in top, lsof, etc
      ensure
        ptr.free if ptr
      end

    end

  end
end