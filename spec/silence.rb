#
# Seeing the dump of pending specs every time you run them is distracting.
# This file lets you skip pending specs.
class Test::Unit::TestResult
  def add_disabled(name)
    #nothing!
  end
end

Adhearsion::Logging.silence!