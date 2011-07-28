require 'adhearsion/script_ahn_loader'

# If we are inside an Adhearsion application this method performs an exec and thus
# the rest of this script is not run.
Adhearsion::ScriptAhnLoader.exec_script_ahn!

require 'adhearsion/commands'
