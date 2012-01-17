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

  config.development do |dev|
    dev.platform.logging.level = :debug
  end

  ##
  # Use with Voxeo PRISM or other Rayo installation
  #
  # config.punchblock.username = "" # Your XMPP JID for use with Rayo
  # config.punchblock.password = "" # Your XMPP password

  ##
  # Use with Asterisk
  #
  # config.punchblock.platform = :asterisk # Your AMI username
  # config.punchblock.username = "" # Your AMI username
  # config.punchblock.password = "" # Your AMI password
  # config.punchblock.host = "127.0.0.1" # Your AMI host
  # config.punchblock.port = 5038 # Your AMI port
end

Adhearsion.router do
  route 'default', SimonGame
end
