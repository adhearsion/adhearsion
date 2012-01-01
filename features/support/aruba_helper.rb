module Aruba
  module Api
    # output() blocks for stderr and stdout it seems
    def interactive_stdout_contains(expected, actual)
      if @interactive
        @interactive.stdout(@aruba_keep_ansi)
        unescape(actual).include?(unescape(expected)) ? true : false
      end
    end
  end
end
