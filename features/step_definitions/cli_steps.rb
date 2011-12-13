Then /^I should see the usage message$/ do
  steps %Q{
    Then the output should contain "Usage:"
    Then the output should contain "ahn create /path/to/directory"
    Then the output should contain "ahn start [console|daemon] [/path/to/directory]"
    Then the output should contain "ahn version|-v|--v|-version|--version"
    Then the output should contain "ahn help|-h|--h|--help|-help"
  }
end
