Feature: Adhearsion Ahn CLI (generate)
  As an Adhearsion user
  I want the ahn command to be able to run generators
  So that I can generate useful code

  Scenario: Listing generators
    When I run `ahn generate`
    Then the output should contain "Please choose a generator below."
    And the output should contain "controller"
