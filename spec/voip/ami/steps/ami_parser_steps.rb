steps_for :ami_parser do
  
  Given("a new parser") do
    @syntax_errors = syntax_errors = []
    @parser = AmiStreamParser.new
    @parser.meta_def(:syntax_error!) { |ignored_chunk| syntax_errors << ignored_chunk }
  end
  
  Given("a version header for AMI $version") do |version|
    @parser << "Asterisk Call Manager/1.0\r\n"
  end
  
  Given("a normal login attempt with events") do
    @parser << fixture('login/standard/client')
  end
  
  When("I parse the protocol") do
    @parser.resume!
  end
  
  Then("the protocol have parsed without syntax errors") do
    @syntax_errors.should be_empty
  end
  
  Then "the version should be set to $version" do |version|
    @parser.ami_version.should eql(version.to_f)
  end
  
end