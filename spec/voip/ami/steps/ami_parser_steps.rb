steps_for :ami_parser do
  
  Given "a new parser" do
    @received_messages = received_messages = []
    @syntax_errors = syntax_errors = []
    @parser = AmiStreamParser.new
    @parser.meta_def(:message_received) { |message| received_messages << @current_message }
    @parser.meta_def(:syntax_error!) { |ignored_chunk| syntax_errors << ignored_chunk }
  end
  
  Given "a version header for AMI $version" do |version|
    @parser << "Asterisk Call Manager/1.0\r\n"
  end
  
  Given "a normal login attempt with events" do
    @parser << fixture('login/standard/success')
  end
  
  Given "a multi-line Response:Follows body of $method_name" do |method_name|
    multi_line_response_body = send method_name

    multi_line_response = format_newlines(<<-RESPONSE + "\r\n") % multi_line_response_body
Response: Follows\r
Privilege: Command\r
ActionID: 123123\r
%s\r
--END COMMAND--\r
RESPONSE

    @parser << multi_line_response
  end
  
  When "I parse the protocol" do
    @parser.resume!
  end
  
  Then "the protocol should have parsed without syntax errors" do
    @syntax_errors.should be_empty
  end
  
  Then "the 'follows' body of $number messages? received should equal $method_name" do |number, method_name|
    multi_line_response = send method_name
    @received_messages.should_not be_empty
    @received_messages.select do |message|
      message.text == multi_line_response
    end.size.should eql(number.to_i)
  end
  
  Then "the version should be set to $version" do |version|
    @parser.ami_version.should eql(version.to_f)
  end
  
end