require File.dirname(__FILE__) + "/story_helper"
require File.dirname(__FILE__) + "/steps/ami_parser_steps"

with_steps_for(:ami_parser) do
  run File.dirname(__FILE__) + "/parser_story"
end
