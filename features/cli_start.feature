Feature: Adhearsion Ahn CLI (start)
  As an Adhearsion user
  I want the ahn command to provide a 'start' command
  So that I can start an interactive Adhearsion application

  Scenario: Command start with no path outside of the app directory
    When I run `ahn start`
    Then the output should contain:
    """
    A valid path is required for start, unless run from an Adhearson app directory
    """
    And the exit status should be 1

  Scenario: Command start with no path inside of the app directory
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I cd to "path/somewhere"
    And I run `ahn start` interactively
    And I wait for output to contain "Starting connection to server"
    Then the output should contain "Adhearsion::Console: Launching Adhearsion Console"
    And the output should contain "AHN>"
    And the output should contain "Adhearsion shut down"

  Scenario: Command start with only path works properly
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I run `ahn start path/somewhere` interactively
    And I wait for output to contain "Starting connection to server"
    Then the output should contain "Adhearsion::Console: Launching Adhearsion Console"
    And the output should contain "AHN>"
    And the output should contain "Adhearsion shut down"
