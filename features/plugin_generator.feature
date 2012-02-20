Feature: Adhearsion plugin generator
  In order to speed up development of an Adhearsion plugin
  As an Adhearsion plugin developer
  I want to generate a plugin and its basic structure

  Scenario: Generate the basic structure for a plugin
    When I run `ahn generate plugin TestPlugin`
    Then the following directories should exist:
    | test_plugin                                         |
    | test_plugin/lib                                     |
    | test_plugin/lib/test_plugin                         |
    | test_plugin/spec                                    |
    And the following files should exist:
    | test_plugin/test_plugin.gemspec                                      |
    | test_plugin/Rakefile                                                 |
    | test_plugin/README.md                                                |
    | test_plugin/Gemfile                                                  |
    | test_plugin/lib/test_plugin.rb                                       |
    | test_plugin/lib/test_plugin/version.rb                               |
    | test_plugin/lib/test_plugin/plugin.rb                                |
    | test_plugin/lib/test_plugin/controller_methods.rb                    |
    | test_plugin/spec/spec_helper.rb                                      |
    | test_plugin/spec/test_plugin/controller_methods_spec.rb              |
    And the file "test_plugin/test_plugin.gemspec" should contain "test_plugin/version"
    And the file "test_plugin/README.md" should contain "TestPlugin"
    And the file "test_plugin/lib/test_plugin.rb" should contain each of these content parts:
    """
    module TestPlugin
    test_plugin/version
    test_plugin/plugin
    test_plugin/controller_methods
    """
    And the file "test_plugin/lib/test_plugin/version.rb" should contain each of these content parts:
    """
    module TestPlugin
    VERSION
    """
    And the file "test_plugin/lib/test_plugin/plugin.rb" should contain each of these content parts:
    """
    module TestPlugin
    init :test_plugin
    config :test_plugin
    namespace :test_plugin
    """
    And the file "test_plugin/lib/test_plugin/controller_methods.rb" should contain each of these content parts:
    """
    module TestPlugin
    def greet
    """
    And the file "test_plugin/spec/spec_helper.rb" should contain "require 'test_plugin'"
    And the file "test_plugin/spec/test_plugin/controller_methods_spec.rb" should contain each of these content parts:
    """
    module TestPlugin
    include TestPlugin::ControllerMethods
    """
