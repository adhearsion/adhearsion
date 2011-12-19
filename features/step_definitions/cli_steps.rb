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

Given /^that "([^"]*)" is valid$/ do |path|
  steps %Q{
    Then the following directories should exist:
      | log |
      | lib |
      | config |
    Then the following files should exist:
      | Gemfile |
      | README |
      | Rakefile |
      | config/adhearsion.rb |
      | config/environment.rb |
  }
end
