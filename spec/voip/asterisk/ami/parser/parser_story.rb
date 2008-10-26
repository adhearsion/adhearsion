require File.dirname(__FILE__) + "/story_helper"

class IntrospectiveManagerStreamParser < Adhearsion::VoIP::Asterisk::Manager::AbstractAsteriskManagerInterfaceStreamParser
  
  attr_reader :received_messages, :syntax_errors, :ami_errors
  def initialize(*args)
    super
    @received_messages = []
    @syntax_errors     = []
    @ami_errors        = []
  end
  
  def message_received(message=@current_message)
    @received_messages << message
  end
  
  def error_received(error_message)
    @ami_errors << error_message
  end
  
  def syntax_error_encountered(ignored_chunk)
    @syntax_errors << ignored_chunk
  end
  
end

steps_for :ami_parser do

  ########################################
  #### GIVEN
  ########################################
  
  Given "a new parser" do
    @parser = IntrospectiveManagerStreamParser.new
    @custom_stanzas = {}
    @custom_events  = {}
    
    @GivenPong = lambda do |with_or_without, action_id, number|
      number = number == "a" ? 1 : number.to_i
      data = case with_or_without
        when "with"    then "Response: Pong\r\nActionID: #{action_id}\r\n\r\n"
        when "without" then "Response: Pong\r\n\r\n"
        else raise "Do not recognize preposition #{with_or_without.inspect}. Should be either 'with' or 'without'"
      end
      number.times do
        @parser << data
      end
    end
  end
  
  Given "a version header for AMI $version" do |version|
    @parser << "Asterisk Call Manager/1.0\r\n"
  end
  
  Given "a normal login success with events" do
    @parser << fixture('login/standard/success')
  end
  
  Given "a normal login success with events split into two pieces" do
    stanza = fixture('login/standard/success')
    @parser << stanza[0...3]
    @parser << stanza[3..-1]
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
--END COMMAND--\r\n\r
    RESPONSE

    @parser << multi_line_response
  end
  
  Given "syntactically invalid $name" do |name|
    @parser << send(:syntax_error_data, name)
  end

  Given "$number Pong responses? with an ActionID of $action_id" do |number, action_id|
    @GivenPong.call "with", action_id, number
  end
  
  Given "$number Pong responses? without an ActionID" do |number|
    @GivenPong.call "without", Time.now.to_f, number
  end  
  
  Given 'a custom stanza named "$name"' do |name|
    @custom_stanzas[name] = "Response: Success\r\n"
  end
  
  Given 'the custom stanza named "$name" has key "$key" with value "$value"' do |name,key,value|
    @custom_stanzas[name] << "#{key}: #{value}\r\n"
  end
  
  Given 'an AMI error whose message is "$message"' do |message|
    @parser << "Response: Error\r\nMessage: #{message}\r\n\r\n"
  end
  
  Given 'an immediate response with text "$text"' do |text|
    @parser << "#{text}\r\n\r\n"
  end
  
  Given 'a custom event with name "$event_name" identified by "$identifier"' do |event_name, identifer|
    @custom_events[identifer] = {:Event => event_name }
  end
  
  Given 'a custom header for event identified by "$identifier" whose key is "$key" and value is "$value"' do |identifier, key, value|
    @custom_events[identifier][key] = value
  end
  
  ########################################
  #### WHEN
  ########################################
  
  When 'the custom stanza named "$name" is added to the buffer' do |name|
    @parser << (@custom_stanzas[name] + "\r\n")
  end
  
  When 'the custom event identified by "$identifier" is added to the buffer' do |identifier|
    custom_event = @custom_events[identifier].clone
    event_name = custom_event.delete :Event
    stringified_event = "Event: #{event_name}\r\n"
    custom_event.each_pair do |key,value|
      stringified_event << "#{key}: #{value}\r\n"
    end
    stringified_event << "\r\n"
    @parser << stringified_event
  end
  
  When "the buffer is parsed" do
    @parser.resume!
  end
  
  ########################################
  #### THEN
  ########################################
  
  Then "the protocol should have parsed without syntax errors" do
    current_pointer     = @parser.send(:instance_variable_get, :@current_pointer)
    data_ending_pointer = @parser.send(:instance_variable_get, :@data_ending_pointer)
    current_pointer.should equal(data_ending_pointer)
    @parser.syntax_errors.should be_empty
  end
  
  Then "the protocol should have parsed with $number syntax errors?" do |number|
    @parser.syntax_errors.size.should equal(number.to_i)
  end
  
  Then "the syntax error fixture named $name should have been encountered" do |name|
    irregularity = send(:syntax_error_data, name)
    @parser.syntax_errors.find { |error| error == irregularity }.should_not be_nil
  end
    
  Then "$number_received messages? should have been received" do |number_received|
    @parser.received_messages.size.should equal(number_received.to_i)
  end
  
  Then "the 'follows' body of $number messages? received should equal $method_name" do |number, method_name|
    multi_line_response = send(:follows_body_text, method_name)
    @parser.received_messages.should_not be_empty
    @parser.received_messages.select do |message|
      message.text == multi_line_response
    end.size.should eql(number.to_i)
  end
  
  Then "the version should be set to $version" do |version|
    @parser.ami_version.should eql(version.to_f)
  end
  
  Then 'the $ordered message received should have a key "$key" with value "$value"' do |ordered,key,value|
    ordered = ordered[/^(\d+)\w+$/, 1].to_i - 1
    @parser.received_messages[ordered][key].should eql(value)
  end
  
  Then "$number AMI error should have been received" do |number|
    @parser.ami_errors.size.should equal(number.to_i)
  end
  
  Then 'the $order AMI error should have the message "$message"' do |order, message|
    order = order[/^(\d+)\w+$/, 1].to_i - 1
    @parser.ami_errors[order].should eql(message)
  end
  
  Then '$number message should be an immediate response with text "$text"' do |number, text|
    @parser.received_messages.select do |response|
      response.kind_of?(Adhearsion::VoIP::Asterisk::Manager::ImmediateResponse) && response.message == text
    end.size.should equal(number.to_i)
  end
  
  Then 'the $order event should have the name "$name"' do |order, name|
    order = order[/^(\d+)\w+$/, 1].to_i - 1
    @parser.received_messages.select do |response|
      response.kind_of?(Adhearsion::VoIP::Asterisk::Manager::Event)
    end[order].name.should eql(name)
  end
  
  Then '$number event should have been received' do |number|
    @parser.received_messages.select do |response|
      response.kind_of?(Adhearsion::VoIP::Asterisk::Manager::Event)
    end.size.should equal(number.to_i)
  end
  
  Then 'the $order event should have key "$key" with value "$value"' do |order, key, value|
    order = order[/^(\d+)\w+$/, 1].to_i - 1
    @parser.received_messages.select do |response|
      response.kind_of?(Adhearsion::VoIP::Asterisk::Manager::Event)
    end[order][key].should eql(value)
  end
  
end

with_steps_for(:ami_parser) do
  run File.dirname(__FILE__) + "/parser_story"
end
