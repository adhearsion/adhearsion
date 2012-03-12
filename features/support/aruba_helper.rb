# encoding: utf-8

module Aruba
  module Api
    # output() blocks for stderr and stdout it seems
    def assert_partial_output_interactive(expected)
      unescape(_read_interactive).include?(unescape(expected)) ? true : false
    end

    def _read_interactive
      @interactive.read_stdout(@aruba_keep_ansi)
    end
  end

  class Process
    def read_stdout(keep_ansi)
      wait_for_io do
        @process.io.stdout.flush
        content = filter_ansi(open(@out.path).read, keep_ansi)
      end
    end
  end
end

