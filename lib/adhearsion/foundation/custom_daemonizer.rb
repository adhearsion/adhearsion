# encoding: utf-8

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
    def daemonize(log_file = '/dev/null')
      srand # Split rand streams between spawning and daemonized process

      # Fork, then exit when the child has exited below
      if pid = safefork
        ::Process.wait pid
        exit
      end

      # Detach from the controlling terminal
      raise 'Cannot detach from controlled terminal' unless sess_id = ::Process.setsid

      # Prevent the possibility of acquiring a controlling terminal
      # Fork again, allow a PID file to be written, then exit
      trap 'SIGHUP', 'IGNORE'

      if pid = safefork
        yield pid if block_given?
        exit
      end

      Dir.chdir "/"   # Release old working directory
      File.umask 0000 # Ensure sensible umask

      STDIN.reopen "/dev/null"
      STDOUT.reopen '/dev/null', "a"
      STDERR.reopen log_file, "a"
      return sess_id
    end
  end
end
