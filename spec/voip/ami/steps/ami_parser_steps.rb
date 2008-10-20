steps_for :ami_parser do
  
  ########################################
  #### GIVEN
  ########################################
  
  Given "a new parser" do
    @received_messages = received_messages = []
    @syntax_errors = syntax_errors = []
    @parser = AmiStreamParser.new
    @parser.meta_def(:message_received) do |*message|
      message = message.first || @current_message
      received_messages << message
    end
    @parser.meta_def(:syntax_error!) { |ignored_chunk| syntax_errors << ignored_chunk }
  end
  
  Given "a version header for AMI $version" do |version|
    @parser << "Asterisk Call Manager/1.0\r\n"
  end
  
  Given "a normal login success with events" do
    @parser << fixture('login/standard/success')
  end
  
  Given "a stanza break" do
    @parser << "\r\n\r\n"
  end
  
  Given "a multi-line Response:Follows body of $method_name" do |method_name|
    multi_line_response_body = send(:follows_body_text, method_name)

    multi_line_response = format_newlines(<<-RESPONSE + "\r\n") % multi_line_response_body
Response: Follows\r
Privilege: Command\r
ActionID: 123123\r
%s\r
--END COMMAND--\r
RESPONSE

    @parser << multi_line_response
  end
  
  Given "syntactically invalid $name" do |name|
    @parser << send(:syntax_error_data, name)
  end
  
  Given "$number Pong responses? $with_or_without an ActionID" do |number, with_or_without|
    number = number == "a" ? 1 : number.to_i
    data = case with_or_without
      when "with"    then "Response: Pong\r\nActionID: 28312.11\r\n\r\n"
      when "without" then "Response: Pong\r\n\r\n"
      else raise "Do not recognize preposition #{with_or_without.inspect}. Should be either 'with' or 'without'"
    end
    number.times do
      @parser << data
    end
  end
  
  ########################################
  #### WHEN
  ########################################
  
  When "I parse the protocol" do
    @parser.resume!
  end
  
  ########################################
  #### THEN
  ########################################
  
  Then "the protocol should have parsed without syntax errors" do
    @syntax_errors.should be_empty
  end
  
  Then "the protocol should have parsed with $number syntax errors?" do |number|
    @syntax_errors.size.should equal(number.to_i)
  end
  
  Then "the syntax error fixture named $name should have been encountered" do |name|
    irregularity = send(:syntax_error_data, name)
    @syntax_errors.find { |error| error == irregularity }.should_not be_nil
  end
  
  Then "$number_received messages? should have been received" do |number_received|
    @received_messages.size.should equal(number_received.to_i)
  end
  
  Then "the 'follows' body of $number messages? received should equal $method_name" do |number, method_name|
    multi_line_response = send(:follows_body_text, method_name)
    @received_messages.should_not be_empty
    @received_messages.select do |message|
      message.text == multi_line_response
    end.size.should eql(number.to_i)
  end
  
  Then "the version should be set to $version" do |version|
    @parser.ami_version.should eql(version.to_f)
  end
  
end