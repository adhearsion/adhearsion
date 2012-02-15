Feature: Adhearsion Ahn CLI (Basic)
  As an Adhearsion user
  I want a cli command (ahn)
  So that I can perform actions against adhearsion apps and interact with adhearsion

  Scenario: No arguments given
    When I run `ahn`
    Then I should see the usage message
    And the exit status should be 0

  Scenario: Unrecognized commands
    When I run `ahn alpha beta`
    Then the output should contain:
    """
    Unknown command: alpha beta
    """
    And the exit status should be 1

  Scenario: Command version should print the version
    When I run `ahn version`
    Then the output should contain:
    """
    Adhearsion v
    """
    And the exit status should be 0

  Scenario: Command help
    When I run `ahn help`
    Then I should see the usage message
    And the exit status should be 0
