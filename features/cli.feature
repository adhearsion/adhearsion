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
      | README                |
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

  Scenario: Command start with no path
    When I run `ahn start`
    Then the output should contain:
    """
    Directory . does not belong to an Adhearsion project!
    """
    And the exit status should be 1

  Scenario: Command daemon with path works correctly
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I run `ahn daemon path/somewhere`
    And I cd to "path/somewhere"
    And I terminate the process using the pid file "adhearsion.pid"
    Then the output should contain "Daemonizing now"
    And the exit status should be 0

  Scenario: Command start with only path works properly
    Given that I create a valid app under "path/somewhere"
    When I run `ahn start path/somewhere` interactively
    And I wait for output to contain "Defining AHN_RAILS"
    And I wait for output to contain "AHN>"
    And I terminate the interactive process
    Then the output should contain "Starting console"
    And the output should contain "Defining AHN_RAILS"
    And the output should contain "Transitioning from booting to running"
    And the output should contain "AHN>"

  Scenario: Command start with daemon and pid option
    Given JRuby skip test
    Given that I create a valid app under "path/somewhere"
    When I run `ahn daemon path/somewhere --pid-file=ahn.pid`
    And I cd to "path/somewhere"
    And I terminate the process using the pid file "ahn.pid"
    Then the output should contain "Daemonizing now"

  Scenario: Command stop with valid path and pid option
    Given that I start a ahn daemon under "path/somewhere"
    When I check for the process with the pid file "ahn.pid" it should be running
    When I run `ahn stop path/somewhere --pid-file=path/somewhere/ahn.pid`
    Then the process identified by the pid file "ahn.pid" should be stopped
    Then the output should contain:
    """
    Stoping Adhearsion app at
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
