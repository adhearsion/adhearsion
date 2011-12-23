Feature: Adhearsion Ahn CLI
  As a Adhearsion user
  I want a cli command (ahn)
  So that I can create and interact with adhearsion apps


  Scenario: No arguments given
    When I run `ahn`
    Then I should see the usage message
    And the exit status should be 0

  Scenario: Unrecoginized commands
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
    Must specify something to create!
    """
    And the exit status should be 1

  Scenario: Command start with no path
    When I run `ahn start`
    Then the output should contain:
    """
    Invalid format for the start CLI command!
    """
    And the exit status should be 1


#  TODO: extend Aruba to support monitoring ouput of interative process
#  Scenario: Cucumber should support checking output on interative commands while they still run
#    Given PENDING: need to finish the
#    Given that I create a valid app under "path/somewhere"
#    When I run `ahn start path/somewhere` interactively
#    And I wait for output to contain "Transitioning"
#    And I terminate the interactive process
#    Then the output should contain:
#    """
#    Transitioning from booting to running
#    """
#    And the exit status should be 0

  Scenario: Command start with only path works properly
    Given that I create a valid app under "path/somewhere"
    And I run `ahn start path/somewhere` interactively
    And I wait 10 seconds
    And I terminate the interactive process
    Then the output should contain:
    """
    Transitioning from booting to running
    """
    Then the exit status should be 0

  Scenario: Command start with daemon option
    Given that I create a valid app under "path/somewhere"
    When I run `ahn start daemon path/somewhere`
    And I cd to "path/somewhere"
    And I terminate the process using the pid file "adhearsion.pid"
    Then the output should contain "Daemonizing now"
    And the exit status should be 0

  Scenario: Command start with console option
    Given that I create a valid app under "path/somewhere"
    When I run `ahn start console path/somewhere` interactively
    And I wait 10 seconds
    #And I tell the console to stop
    And I terminate the interactive process
    Then the output should contain "Starting console"
    #And the output should contain "AHN>"

  Scenario: Command start with both console and daemon options
    Given I run `ahn create path/somewhere`
    When I run `ahn start console daemon path/somewhere`
    Then the output should contain:
    """
    Unrecognized final argument
    """
    Then the exit status should be 1

  Scenario: Command start with daemon and pid option
    Given that I create a valid app under "path/somewhere"
    When I run `ahn start daemon path/somewhere --pid-file=ahn.pid`
    And I cd to "path/somewhere"
    And I terminate the process using the pid file "ahn.pid"
    Then the output should contain "Daemonizing now"

 #TODO: change ahnctl to ahn
 #FIXME: ahnctl used current path while ahn uses relative (to app) path
  Scenario: Command start with valid path and pid option
    Given PENDING
    Given that I create a valid app under "path/somewhere"
    When I run `ahnctl start path/somewhere --pid-file=path/somewhere/ahn.pid`
    And I cd to "path/somewhere"
    And I terminate the process using the pid file "ahn.pid"
    Then the output should contain:
    """
    Starting Adhearsion app at
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

  Scenario: Ahnctl with no arguments
    When I run `ahnctl`
    Then the output should contain:
    """
    Usage: ahnctl start|stop|restart /path/to/adhearsion/app [--pid-file=/path/to/pid_file.pid]
    """
