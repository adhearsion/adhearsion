Feature: Adhearsion Ahn CLI (generate)
  As an Adhearsion user
  I want the ahn command to be able to run generators
  So that I can generate useful code

  Scenario: Listing generators
    When I run `ahn generate`
    Then the output should contain "Available generators:"
    And the output should contain "controller [controller_name]: A call controller template. 'controller_name' should be the disired class name, either CamelCase or under_scored."
    Then the output should contain "plugin [plugin_name]: A plugin template. 'plugin_name' should be the disired plugin module name, either CamelCase or under_scored."

  Scenario: Generator help
    When I run `ahn help generate`
    Then the output should contain "controller [controller_name]: A call controller template. 'controller_name' should be the disired class name, either CamelCase or under_scored."
    Then the output should contain "plugin [plugin_name]: A plugin template. 'plugin_name' should be the disired plugin module name, either CamelCase or under_scored."
