# encoding: utf-8

Then /^I should see the usage message$/ do
  steps %Q{
    Then the output should contain "ahn create"
    Then the output should contain "ahn start"
    Then the output should contain "ahn daemon"
    Then the output should contain "ahn version"
    Then the output should contain "ahn plugin"
    Then the output should contain "ahn help"
  }
end

Then /^I should see the plugin usage message$/ do
  steps %Q{
    Then the output should contain "ahn plugin create_ahnhub_hooks"
    Then the output should contain "ahn plugin create_github_hook"
    Then the output should contain "ahn plugin create_rubygem_hook"
  }
end

When /^I wait (\d+) seconds?$/ do |arg1|
  sleep arg1.to_i
end

Given /^that I create a valid app under "([^"]*)"$/ do |path|
  steps %Q{
    When I run `ahn create #{path}`
    Then there should be a valid adhearsion directory named "#{path}"
  }

  remove_file "#{path}/Gemfile"
end

Then /^there should be a valid adhearsion directory named "([^"]*)"$/ do |path|
  steps %Q{
    Then a directory named "#{path}" should exist
  }

  cd(path)
  steps %Q{
    Then the following directories should exist:
      | lib |
      | config |
    Then the following files should exist:
      | Gemfile |
      | README.md |
      | Rakefile |
      | config/adhearsion.rb |
      | config/environment.rb |
  }

  ## NOTE: Aruba's cd method is not really changing directories
  ## Either we use cd or we need absolute path... could not figure out cleaner
  ## way to get back to previous dir.
  dotsback=1.upto(path.split(File::SEPARATOR)[0..-1].count).collect {|x| ".."}.join(File::SEPARATOR)
  dotsback.shift if dotsback[0].is_a?(String) and dotsback[0].empty?
  cd(dotsback)
end

When /^I terminate the process using the pid file "([^"]*)"$/ do |pidfile|
  check_file_presence([pidfile], true)
  prep_for_fs_check do
    pid = File.read(pidfile).to_i
    Process.kill("TERM", pid)
    sleep 1
  end
end

