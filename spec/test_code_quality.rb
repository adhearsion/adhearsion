# #!/usr/bin/env spec
# 
# # TODO: Forget regexps. Use Rubinius.
# # This spec is somewhat unique. It essentially reads the code
# # and ensures the best practices are followed.
# 
# # TODO: Create a be_a_proper_method_definition assertion
# # TODO: Create a syntax checking spec
# # TODO: Report code that has spaces between the dot when defining the method on an object
# 
# module CodeQualityHelper
#   # TODO: Allow strings with a Hash in them before it
#   
#   BadMethodRegexp = /def\s+([$@]?[a-zA-Z_][\w_]*\s*\.\s*)?[a-zA-Z_][\w_]*[=!?]?[^(^\Z]/
#   @root = File.dirname(__FILE__) + "/.."
#   
#   def ruby_files
#     @ruby_files ||= Dir[@root + "/**/*.rb"].map { |f| File.expand_path f }
#   end
#   
# end
# 
# describe "My 'bad method definition' finding regular expression" do
#   
#   # ATTENTION: If this spec ever blows up for a method definition it shouldn't,
#   # please add the definition that caused it to explode here as an assertion.
#   # It would also be nice to fix the regular expression too :)
#   
#   include CodeQualityHelper
#   
#   it "should NOT match method definitions with no arguments" do
#     "def foo".should !~ CodeQualityHelper::BadMethodRegexp
#     " def    monkey   ".should !~ CodeQualityHelper::BadMethodRegexp
#     ' unless "#{bar}".empty? then def @zebra.spock '.should !~ CodeQualityHelper::BadMethodRegexp
#   end
#   
#   it "should NOT match method definitions with arguments and parenthesis" do
#     "def foo(bar)".should !~ CodeQualityHelper::BadMethodRegexp
#     "\tdef $MONKEY . foo( bar, qaz = blam!) ".should !~ CodeQualityHelper::BadMethodRegexp
#     "if(this) then def $MONKEY . foo( qaz = blam!, *args, &b) ".should !~ CodeQualityHelper::BadMethodRegexp
#     " @something.each do |x| def something".should !~ CodeQualityHelper::BadMethodRegexp
#   end
#   
#   it "should match method definitions with a space between the name and parenthesis" do
#     "def foo (bar)".should =~ CodeQualityHelper::BadMethodRegexp
#     "def  \t m \t (*args)".should =~ CodeQualityHelper::BadMethodRegexp
#   end
#   
#   it "should match method definitions with no parenthesis around its arguments" do
#     "def foo bar".should =~ CodeQualityHelper::BadMethodRegexp
#     "\tif $x then def foo bar # Commentacular".should =~ CodeQualityHelper::BadMethodRegexp
#   end
# end
# 
# describe "All method definitions" do
#   
#   include CodeQualityHelper
#   
#   before:all do
#     @root = File.dirname(__FILE__) + "/.."
#   end
#   
#   it "should have parenthesis around their arguments" do
#     ruby_files.each do |file|
#       puts file
#       File.read(file).grep(CodeQualityHelper::BadMethodRegexp).should be_empty
#     end
#   end
# end
# 
# # describe "The syntax of all Ruby source files" do
# #   
# #   include CodeQualityHelper
# #   
# #   before:all do
# #     @root = File.dirname(__FILE__) + "/.."
# #   end
# #   
# #   it "should be valid" do
# #     incorrect = ruby_files.map { |f| File.expand_path f }.select do |file|
# #       `ruby -c #{file}`
# #       not $?.success?
# #     end
# #     
# #     incorrect.should be_empty
# #   end
# # end