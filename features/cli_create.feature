Feature: Adhearsion Ahn CLI (Create)
  As an Adhearsion user
  I want the ahn command to allow creating an app
  So that I can write an Adhearsion app

  Scenario: Command create with correct arguments
    When I run `ahn create path/somewhere`
    And I cd to "path/somewhere"
    Then the following files should exist:
      | Gemfile               |
      | README.md             |
      | Rakefile              |
      | config/adhearsion.rb  |
      | config/environment.rb |
      | spec/spec_helper.rb   |
    And the file "config/adhearsion.rb" should contain "Adhearsion.router"
    Then the exit status should be 0

  Scenario: Running create with no arguments
    When I run `ahn create`
    Then the output should contain:
    """
    no arguments
    """
    And the exit status should be 1
