Feature: Adhearsion Ahn CLI
  As a Adhearsion user
  I want a cli command (ahn)
  So that I can create and interact with adhearsion apps

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

  Scenario: Command create with correct arguments
    When I run `ahn create path/somewhere`
    And I cd to "path/somewhere"
    Then the following files should exist:
      | Gemfile               |
      | README.md             |
      | Rakefile              |
      | config/adhearsion.rb  |
      | config/environment.rb |
    And the file "config/adhearsion.rb" should contain "Adhearsion.router"
    Then the exit status should be 0

  Scenario: Running create with no arguments
    When I run `ahn create`
    Then the output should contain:
    """
    "create" was called incorrectly. Call as "ahn create /path/to/directory".
    """
    And the exit status should be 1

  Scenario: Command start with no path outside of the app directory
    When I run `ahn start`
    Then the output should contain:
    """
    A valid path is required for start, unless run from an Adhearson app directory
    """
    And the exit status should be 1

  Scenario: Command start with no path inside of the app directory
    Given that I create a valid app under "path/somewhere"
    When I cd to "path/somewhere"
    And I run `ahn start` interactively
    And I wait for output to contain "Transitioning from booting to running"
    And I terminate the interactive process
    Then the output should contain "Loaded config"
    And the output should contain "Adhearsion::Console: Starting up..."
    And the output should contain "AHN>"
    And the output should contain "Starting connection"
    And the output should contain "Transitioning from running to stopping"

  Scenario: Command start with only path works properly
    Given that I create a valid app under "path/somewhere"
    When I run `ahn start path/somewhere` interactively
    And I wait for output to contain "Transitioning from booting to running"
    And I terminate the interactive process
    Then the output should contain "Loaded config"
    And the output should contain "Adhearsion::Console: Starting up..."
    And the output should contain "AHN>"
    And the output should contain "Starting connection"
    And the output should contain "Transitioning from running to stopping"

  Scenario: Command daemon with path works correctly
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I run `ahn daemon path/somewhere`
    And I cd to "path/somewhere"
    And I terminate the process using the pid file "adhearsion.pid"
    Then the output should contain "Daemonizing now"
    And the exit status should be 0

  Scenario: Command start with daemon and pid option
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I run `ahn daemon path/somewhere --pid-file=ahn.pid`
    And I cd to "path/somewhere"
    And I terminate the process using the pid file "ahn.pid"
    Then the output should contain "Daemonizing now"

  Scenario: Command stop with valid path and pid option
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I run `ahn daemon path/somewhere --pid-file=ahn.pid`
    And I run `ahn stop path/somewhere --pid-file=ahn.pid`
    Then the output should contain:
    """
    Stopping Adhearsion
    """

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
