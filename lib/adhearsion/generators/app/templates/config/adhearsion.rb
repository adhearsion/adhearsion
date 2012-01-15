# Centralized way to overwrite any Adhearsion platform or plugin configuration
# - Execute rake adhearsion:config:desc to get the configuration options
# - Execute rake adhearsion:config:show to get the configuration values
#
# To update a plugin configuration you can write either:
#
#    * Option 1
#        Adhearsion.config.<plugin-name> do |config|
#          config.<key> = <value>
#        end
#
#    * Option 2
#        Adhearsion.config do |config|
#          config.<plugin-name>.<key> = <value>
#        end

Adhearsion.config do |config|

  # config.platform.logging.level = :debug

  # Overwrite default punchblock credentials
  #config.punchblock.username = ""
  #config.punchblock.password = ""
end

Adhearsion.router do
  route 'default', SimonGame
end
