Feature: Adhearsion Ahn CLI (stop)
  As an Adhearsion user
  I want the ahn command to provide a 'stop' command
  So that I can stop a running Adhearsion daemon

  @reconnect
  Scenario: Command stop with valid path and pid option
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I run `ahn daemon path/somewhere --pid-file=ahn.pid`
    And I run `ahn stop path/somewhere --pid-file=ahn.pid`
    Then the output should contain:
    """
    Stopping Adhearsion
    """
    And the file "ahn.pid" should not exist

  @reconnect
  Scenario: Command stop with valid path and no pid option
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I run `ahn daemon path/somewhere`
    And I run `ahn stop path/somewhere`
    Then the output should contain:
    """
    Stopping Adhearsion
    """
    And the file "path/somewhere/adhearsion.pid" should not exist

  @reconnect
  Scenario: Command stop with no options inside the app directory
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    And I cd to "path/somewhere"
    When I run `ahn daemon`
    And I run `ahn stop`
    Then the output should contain:
    """
    Stopping Adhearsion
    """
    And the file "adhearsion.pid" should not exist
