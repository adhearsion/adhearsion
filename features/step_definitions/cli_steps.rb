require 'timeout'

Then /^I should see the usage message$/ do
  steps %Q{
    Then the output should contain "Usage:"
    Then the output should contain "ahn create /path/to/directory"
    Then the output should contain "ahn start [console|daemon] [/path/to/directory]"
    Then the output should contain "ahn version|-v|--v|-version|--version"
    Then the output should contain "ahn help|-h|--h|--help|-help"
  }
end

# TODO: send pull request for cucumber.rb
When /^I terminate the interactive process$/ do
  terminate_processes!
end

When /^I wait (\d+) seconds?$/ do |arg1|
  sleep arg1.to_i
end

# TODO: send pull request for cucumber.rb
When /^I wait for (?:output|stdout) to contain "([^"]*)"$/ do |expected|
  Timeout::timeout(@aruba_io_wait_seconds) do
    loop do
      break if assert_partial_output_interactive(expected)
      sleep 0.1
    end
  end
end

Given /^that I create a valid app under "([^"]*)"$/ do |path|
  steps %Q{
    When I run `ahn create #{path}`
    Then there should be a valid adhearsion directory named "#{path}"
  }
end

Then /^there should be a valid adhearsion directory named "([^"]*)"$/ do |path|
  steps %Q{
    Then a directory named "#{path}" should exist
  }
  ## Either we use cd or we need absolute path... could not figure out cleaner
  ## way to get back to previous dir.
  cd(path)
  steps %Q{
    Then the following directories should exist:
      | lib |
      | config |
    Then the following files should exist:
      | Gemfile |
      | README |
      | Rakefile |
      | config/adhearsion.rb |
      | config/environment.rb |
  }
  dotsback=1.upto(path.split(File::SEPARATOR)[0..-1].count).collect {|x| ".."}.join(File::SEPARATOR)
  dotsback.shift if dotsback[0].class == String and dotsback[0].empty?
  cd(dotsback)
end

When /^I terminate the process using the pid file "([^"]*)"$/ do |pidfile|
  check_file_presence([pidfile], true)
  prep_for_fs_check do
    pid = File.read(pidfile).to_i
    Process.kill("TERM", pid)
  end
end

# FIXME: force_stop does not stop process from starting...
When /^I tell the console to stop$/ do
  steps %Q{When I type "Adhearsion::Process.force_stop"}
end
