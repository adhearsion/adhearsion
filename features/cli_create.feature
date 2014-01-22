Feature: Adhearsion Ahn CLI (Create)
  As an Adhearsion user
  I want the ahn command to allow creating an app
  So that I can write an Adhearsion app

  Scenario: Generate application with valid layout
    When I run `ahn create path/somewhere`
    And I cd to "path/somewhere"
    Then the following directories should exist:
      | app/call_controllers  |
      | lib                   |
      | config                |
      | script                |
      | spec                  |
      | spec/call_controllers |
      | spec/support          |

    And the following files should exist:
      | .gitignore                                |
      | .rspec                                    |
      | app/call_controllers/simon_game.rb        |
      | config/adhearsion.rb                      |
      | config/environment.rb                     |
      | config/events.rb                          |
      | config/routes.rb                          |
      | Gemfile                                   |
      | script/ahn                                |
      | spec/spec_helper.rb                       |
      | spec/call_controllers/simon_game_spec.rb  |
      | README.md                                 |
      | Rakefile                                  |
      | Procfile                                  |

    And the file "config/adhearsion.rb" should contain each of these content parts:
    """
    Adhearsion.config
    logging.level
    config.punchblock
    """
    And the file "config/events.rb" should contain each of these content parts:
    """
    Adhearsion::Events.draw do
    """
    And the file "config/routes.rb" should contain each of these content parts:
    """
    Adhearsion.router
    """
    And the file "README.md" should contain each of these content parts:
    """
    Start your new app with
    AGI(agi
    """
    And the file "Rakefile" should contain "adhearsion/tasks"
    And the file "Gemfile" should contain each of these content parts:
    """
    source 'https://rubygems.org
    gem 'adhearsion-asr'
    """
    And the file "app/call_controllers/simon_game.rb" should contain "class SimonGame"
    And the file "script/ahn" should contain "require 'adhearsion'"

  Scenario: Generate application --empty
    When I run `ahn create path/somewhere --empty`
    And I cd to "path/somewhere"
    Then the following directories should exist:
      | app/call_controllers  |
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
      | config/events.rb      |
      | config/routes.rb      |
      | Gemfile               |
      | script/ahn            |
      | spec/spec_helper.rb   |
      | README.md             |
      | Rakefile              |
      | Procfile              |

    And the following files should not exist:
      | app/call_controllers/simon_game.rb        |
      | spec/call_controllers/simon_game_spec.rb  |

    And the file "config/adhearsion.rb" should not contain each of these content parts:
    """
    # Register global handlers for events
    """

  Scenario: Running create with no arguments
    When I run `ahn create`
    Then the output should contain:
    """
    no arguments
    """
    And the exit status should be 1
