Feature: Adhearsion Ahn CLI (restart)
  As an Adhearsion user
  I want the ahn command to provide a 'restart' command
  So that I can restart a running Adhearsion daemon

  @reconnect
  Scenario: Command restart with a missing or wrong pid
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I run `ahn daemon path/somewhere --pid-file=ahn.pid`
    And I run `ahn restart path/somewhere --pid-file=ahn2.pid`
    Then the output should contain:
    """
    Could not read pid from the file
    """
    And the output should contain:
    """
    Starting Adhearsion
    """

  @reconnect
  Scenario: Command restart with no path outside of the app directory
    Given that I create a valid app under "path/somewhere"
    When I run `ahn daemon path/somewhere --pid-file=ahn.pid`
    And I run `ahn restart --pid-file=ahn.pid`
    Then the output should contain:
    """
    A valid path is required for restart, unless run from an Adhearson app directory
    """
    And the exit status should be 1

  @reconnect
  Scenario: Command restart with no path inside of the app directory
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I cd to "path/somewhere"
    And I run `ahn daemon --pid-file=ahn.pid`
    And I run `ahn restart --pid-file=ahn.pid`
    Then the output should contain:
    """
    Starting Adhearsion
    """
    And the exit status should be 0