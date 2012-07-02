Feature: Adhearsion App Generator
  In order to do development on new Adhearsion apps
  As an Adhearsion developer
  I want to generate an Adhearsion app

  Scenario: Generate application with valid layout
    When I run `ahn create path/somewhere`
    And I cd to "path/somewhere"
    Then the following directories should exist:
      | lib                   |
      | config                |
      | script                |
      | spec                  |
      | spec/call_controllers |
      | spec/support          |

    And the following files should exist:
      | .gitignore            |
      | .rspec                |
      | config/adhearsion.rb  |
      | config/environment.rb |
      | Gemfile               |
      | lib/simon_game.rb     |
      | script/ahn            |
      | spec/spec_helper.rb   |
      | README.md             |
      | Rakefile              |
      | Procfile              |

    And the file "config/adhearsion.rb" should contain each of these content parts:
    """
    Adhearsion.router
    Adhearsion.config
    logging.level
    config.punchblock
    """
    And the file "README.md" should contain each of these content parts:
    """
    Start your new app with
    AGI(agi
    """
    And the file "Rakefile" should contain "adhearsion/tasks"
    And the file "Gemfile" should contain each of these content parts:
    """
    source :rubygems
    gem 'adhearsion-asterisk'
    """
    And the file "lib/simon_game.rb" should contain "class SimonGame"
    And the file "script/ahn" should contain "require 'adhearsion'"
