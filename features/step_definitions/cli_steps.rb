Then /^I should see the usage message$/ do
  steps %Q{
    Then the output should contain "Usage:"
    Then the output should contain "ahn create /path/to/directory"
    Then the output should contain "ahn start [console|daemon] [/path/to/directory]"
    Then the output should contain "ahn version|-v|--v|-version|--version"
    Then the output should contain "ahn help|-h|--h|--help|-help"
  }
end

When /^I terminate the interactive process$/ do
  terminate_processes!
end

When /^I wait (\d+) seconds?$/ do |arg1|
  sleep arg1.to_i
end

When /^I wait for (?:output|stdout) to contain "([^"]*)"$/ do |expected|
  loop do
    break if interactive_stdout_contains(expected, all_output)
    sleep 0.5
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
  ## TODO: allow chdir to the path then back out again
  cd
  steps %Q{
    Then the following directories should exist:
      | #{path}/lib |
      | #{path}/config |
    Then the following files should exist:
      | #{path}/Gemfile |
      | #{path}/README |
      | #{path}/Rakefile |
      | #{path}/config/adhearsion.rb |
      | #{path}/config/environment.rb |
  }
end
