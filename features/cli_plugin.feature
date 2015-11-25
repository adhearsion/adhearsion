Feature: Adhearsion Ahn CLI (Plugin)
  As an Adhearsion user
  I want a cli command (ahn plugin)
  So that I can perform actions for adhearsion plugins

  Scenario: No arguments given
    When I run `ahn plugin`
    Then I should see the plugin usage message
    And the exit status should be 0

  Scenario: Unrecognized commands
    When I run `ahn plugin alpha beta`
    Then the output should contain:
    """
    Could not find command "alpha"
    """
    And the exit status should be 1

  Scenario: Command help
    When I run `ahn plugin help`
    Then I should see the plugin usage message
    And the exit status should be 0

  Scenario: Command create_rubygem_hook
    When I run `ahn plugin create_rubygem_hook` interactively
    And I type "foobar"
    And I type "SECRET_CODE"
    Then the output should contain:
    """
    Access Denied.
    """

  Scenario: Command create_github_hook
    When I run `ahn plugin create_github_hook` interactively
    And I type "username"
    And I type "SECRET_CODE"
    And I type "adhearsion/new_plugin"
    Then the output should contain:
    """
    {"message":
    """
