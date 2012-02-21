Feature: Adhearsion controller generator
  In order to speed up development of an Adhearsion app
  As an Adhearsion developer
  I want to generate a controller and its tests

  Scenario: Generate a controller and a test file
    When I run `ahn create path/somewhere`
    And I cd to "path/somewhere"
    And I run `ahn generate controller TestController`
    Then the following directories should exist:
      | lib                           |
      | spec                          |

    And the following files should exist:
      | lib/test_controller.rb         |
      | spec/test_controller_spec.rb |

    And the file "lib/test_controller.rb" should contain "class TestController < Adhearsion::CallController"
    And the file "spec/test_controller_spec.rb" should contain "describe TestController"
