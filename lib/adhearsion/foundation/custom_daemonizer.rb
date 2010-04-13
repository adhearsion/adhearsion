# This is largely based on the Daemonize library by Travis Whitton and
# Judson Lester. http://grub.ath.cx/daemonize. I cleaned it up a bit to
# meet Adhearsion's quality standards.
module Adhearsion
  module CustomDaemonizer
  
    # Try to fork if at all possible retrying every 5 sec if the
    # maximum process limit for the system has been reached
    def safefork
      begin
        pid = fork
        return pid if pid
      rescue Errno::EWOULDBLOCK
        sleep 5
        retry
      end
    end

    # This method causes the current running process to become a daemon
    def daemonize(log_file='/dev/null')
      oldmode = 0
      srand # Split rand streams between spawning and daemonized process
      safefork and exit # Fork and exit from the parent

      # Detach from the controlling terminal
      unless sess_id = Process.setsid
        raise 'Cannot detach from controlled terminal'
      end

      # Prevent the possibility of acquiring a controlling terminal
      if oldmode.zero?
        trap 'SIGHUP', 'IGNORE'
        exit if pid = safefork
      end

      Dir.chdir "/"   # Release old working directory
      File.umask 0000 # Ensure sensible umask

      STDIN.reopen "/dev/null"
      STDOUT.reopen '/dev/null', "a"
      STDERR.reopen log_file, "a"
      return oldmode ? sess_id : 0
    end
  end
end