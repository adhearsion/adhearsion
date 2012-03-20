Feature: Adhearsion Ahn CLI (stop)
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
