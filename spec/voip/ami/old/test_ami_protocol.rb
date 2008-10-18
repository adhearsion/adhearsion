require File.join(File.dirname(__FILE__), "ami_helper")
require 'adhearsion/voip/asterisk/new-ami/ami'

# MUST ALWAYS SEPARATE THE COLONS WITH WHITESPAC
# TEST THAT IT CAN PARSE EVENTS

context "Establishing a socket" do
  
  include AmiProtocolTestHelper
  
  attr_reader :parser
  before :each do
    @parser = new_parser
  end
  
  it "should read the AMI version at the beginning" do
    sample_version = 99.76234 # Doesn't matter
    parser << "Asterisk Call Manager/#{sample_version}\r\n"
    parser.ami_version.should.equal sample_version
  end
  
  it "should raise an error when the version is not there" do
    the_following_code {
      parser << "Asterisk Call Manager/1.0\r\n"
      parser.ami_version.should.not.be.nil
    }.should.not.raise
  end
end

context "Reading of an action" do
  
  include AmiProtocolTestHelper
  
  attr_reader :parser
  before :each do
    @parser = new_parser
    flexmock(@parser).should_receive(:syntax_error!).never
  end
  
  it "should handle a 'Response: Follows' action properly" do

    multi_line_response_body = %{Ragel is a software development tool that allows user actions to
    be embedded into the transitions of a regular expression’s corresponding state machine,
    eliminating the need to switch from the regular expression engine and user code execution
    environment and back again.}

    multi_line_response = format_newlines <<-RESPONSE + "\r\n"
Response: Follows\r
Privilege: Command\r
ActionID: 123123\r
#{multi_line_response_body}\r
--END COMMAND--\r
RESPONSE
    
    parser.meta_def(:message_received) do |message|
      message.text.should == multi_line_response_body
      throw :got_here!
    end
    
    # flexmock(parser).should_receive(:message_received).once
    # the_following_code {
      parser << multi_line_response
    # }.should.throw :got_here!
  end
  
  it "should work with a pong containing an Action ID" do
    pong = fixture("pong/with_action_id")
    parser << (pong * 2)
    parser.send(:instance_variable_get, :@current_pointer).should.equal(pong.size * 2)
  end
  
  it "should work with a pong not containing an action ID" do  
    pong = fixture("pong/without_action_id")
    parser << (pong * 2)
    parser.send(:instance_variable_get, :@current_pointer).should.equal(pong.size * 2)
  end
  
  it "should work with a pong not containing arbitrary key/value pairs" do  
    pong = fixture("pong/with_extra_keys")
    parser << (pong * 2)
    parser.send(:instance_variable_get, :@current_pointer).should.equal(pong.size * 2)
  end
  
  it "should resume when given an arbirary amount of data" do
    flexmock(parser).should_receive(:ami_error!).once.and_return nil
    error_message = fixture 'errors/missing_action'
    piece_one = error_message[0...3]
    piece_two = error_message[3..-1]
    parser << piece_one
    parser << piece_two
  end
    
  it "should tell ami_error! when an error comes in" do
    flexmock(parser).should_receive(:ami_error!).once.and_return nil
    error_message = "Response: Error\r\nMessage: Missing action in request\r\n\r\n"
    parser << fixture('errors/missing_action')
  end
  
  it "should let the buffer grow when it's not full" do
    error_message = fixture 'errors/missing_action'
    parser << error_message
    parser << error_message
    parser.send(:instance_variable_get, :@data_ending_pointer).should.equal error_message.size * 2
  end
  
  it "should read a properly formatted stanza properly" do
    times = 3
    flexmock(parser).should_receive(:message_received).times(times).and_return nil
    data = fixture("login/standard/success")
    data *= times
    parser << data
  end
  
end

context "Syntax errors" do
  
  include AmiProtocolTestHelper
  
  attr_reader :parser
  before :each do
    @parser = new_parser
  end
  
  it "should recover from unexpected protocol irregularities" do
    fuzz = "!IJ@MHY!&@B*!B @ ! @^! @ !@ !\r!@ ! @ !@ ! !!m, \n\\n\n"
    flexmock(parser).should_receive(:ami_error!).once.and_return nil
    flexmock(parser).should_receive(:message_received).once.and_return nil
    flexmock(parser).should_receive(:syntax_error!).once.with(fuzz)
    data_simulation = fixture('errors/missing_action') + fuzz + "\r\n\r\n" + fixture('login/standard/success')
    parser << data_simulation
  end
  
end

context "AmiProtocolTestHelper" do
  
  include AmiProtocolTestHelper
  
  it "should only replace newlines not preceded by carriage returns" do
    before, after = "   i am\n  on a line\r\nkthxbai\n",
                    "   i am\r\n  on a line\r\nkthxbai\r\n"
    format_newlines(before).should == after
  end
end

BEGIN {
  module AmiProtocolTestHelper
  
    def format_newlines(string)
      # HOLY FUCK THIS IS UGLY
      tmp_replacement = random_string
      string.gsub("\r\n", tmp_replacement).
             gsub("\n", "\r\n").
             gsub(tmp_replacement, "\r\n")
    end
 
    def parse_string(string)
      new_parser.execute_with string
    end
 
    def new_parser
      AmiStreamParser.new
    end
    
    def line_reader_for(stream, line_handler)
      BufferedLineReadingStream.new stream, line_handler
    end
    
    def action_proxy_with_mock_socket_sending(&block)
      
    end
    
    def a_socket_sending_only(data)
      StringIO.new data
    end
    
    def message_recipient(&block)
      returning Object.new do |obj|
        obj.meta_def(:continue_with_line) do |data|
          block.call data
        end
      end
    end
    
    private
    
    def random_string
      (rand(1_000_000_000_000) + 1_000_000_000).to_s
    end
  end
}
