module Aruba
  module Api
    def terminate_processes!
      processes.each do |_, process|
        terminate_process(process)
        stop_process(process)
      end
    end

    def terminate_process(process)
      process.terminate(@aruba_keep_ansi)
    end

    # output() blocks for stderr and stdout it seems
    def interactive_stdout_contains(expected, actual)
      if @interactive
        @interactive.stdout(@aruba_keep_ansi)
        unescape(actual).include?(unescape(expected)) ? true : false
      end
    end
  end

  class Process
    def terminate(keep_ansi)
      if @process
        stdout(keep_ansi) && stderr(keep_ansi) # flush output
        @process.stop
        stdout(keep_ansi) && stderr(keep_ansi) # flush output
      end
    end
  end
end
