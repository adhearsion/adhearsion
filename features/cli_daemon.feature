Feature: Adhearsion Ahn CLI (daemon)
  As an Adhearsion user
  I want the ahn command to provide a 'daemon' command
  So that I can start my adhearsion app as a daemon

  @reconnect
  Scenario: Command daemon with path works correctly
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I run `ahn daemon path/somewhere`
    And I cd to "path/somewhere"
    And I terminate the process using the pid file "adhearsion.pid"
    Then the exit status should be 0

  @reconnect
  Scenario: Command daemon with pid option
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I run `ahn daemon path/somewhere --pid-file=ahn.pid`
    And I cd to "path/somewhere"
    And I terminate the process using the pid file "ahn.pid"
    Then the exit status should be 0
