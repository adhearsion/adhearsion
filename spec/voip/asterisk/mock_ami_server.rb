class AmiServer
  class AMIResponseHelper
    class << self
      def bad_login_response
        { "Response" => "Error", "Message" => "Authentication failed" }
      end

      def good_login_response
        { "Response" => "Success", "Message" => "Authentication accepted" }
      end
      
      def follows_response
        { "Response" => "Follows", "Privilege" => "Command" }
      end

      def bad_dbget_response
        { "Response" => "Error", "Message" => "Database entry not found" }
      end

      def good_dbget_response
        { "Response" => "Success", "Message" => "Result will follow" }
      end

      def dbput_response
        { "Response" => "Success", "Message" => "Updated database successfully" }
      end
      
      def dbget_event_response
        { "Event" => "DBGetResponse" }
      end
      
      def queue_status_response
        { "Response" => "Success", "Message" => "Queue status will follow" }
      end

      def queue_status_event_complete_response
        { "Event" => "QueueStatusComplete" }
      end

      def queue_status_event_params_response
        { "Event" => "QueueParams", "Queue" => "default", "Max" => 0, "Min" => 0, "Holdtime" => 0,
          "Completed" => 0, "Abandoned" => 0, "ServiceLevel" => 0, "ServiceLevelPerf" => 0 }
      end

      def events_on_response
        { "Response" => "Events On" }
      end

      def events_off_response
        { "Response" => "Events Off" }
      end
      
      def ping_response
        { "Response" => "Pong" }
      end
    end
  end

  def initialize(*args)
    @closed = false
    @buffer = ""
    @db = {}
    extend MonitorMixin
    fill(prompt, 1)
  end

  def closed?
    @closed
  end
  
  def close
    @closed = true
  end

  def read_nonblock(count)
    str = @buffer.slice!(0..count-1)
    raise Errno::EAGAIN if str == ""
    str
  end
  
  def gets
    @buffer.slice!(0..-1)
  end

  def write(str)
    raise ArgumentError, "malformed request" if not str.ends_with?("\r\n\r\n")
    args = str.split("\r\n").inject({}) { |accum, str| accum.merge!(YAML.load(str)) }
    actionid = args['actionid']
    case args['action']
      when "login"
        if args['username'] == username and args['secret'] == password
          fill(response(actionid, AMIResponseHelper.good_login_response))
        else
          fill(response(actionid, AMIResponseHelper.bad_login_response))
        end
      when "queues"
        fill("No Members\nNo Callers\r\n")
      when "command"
        case args['command']
        when "show channels"
          fill(response(actionid, AMIResponseHelper.follows_response), 1)
          fill("Channel (Context Extension Pri ) State Appl. Data\n0 active channel(s)\r\n--END COMMAND--")
        else
          fill(response(actionid, AMIResponseHelper.follows_response), 1)
          fill("No such command '#{args['command']}' (type 'help' for help)\r\n--END COMMAND--")
        end
      when "dbget"
        if not @db.has_key?(args['family']) or not @db[args['family']].has_key?(args['key'])
          fill(response(actionid, AMIResponseHelper.bad_dbget_response))
        else
          val = @db[args['family']][args['key']]
          fill(response(actionid, AMIResponseHelper.good_dbget_response))
          fill(response(actionid, {
            :Family => args['family'],
            :Key    => args['key'],
            :Val    => val }.merge!(AMIResponseHelper.dbget_event_response)))
        end
      when "dbput"
        @db[args['family']] ||= {}
        @db[args['family']][args['key']] = args['val']
        fill(response(actionid, AMIResponseHelper.dbput_response))
      when "queuestatus"
        fill(response(actionid, AMIResponseHelper.queue_status_response))
        fill(response(actionid, AMIResponseHelper.queue_status_event_params_response))
        fill(response(actionid, AMIResponseHelper.queue_status_event_complete_response))
      when "events"
        if args['eventmask'] !~ /^on$/i
          if args['eventmask'] =~ /^off$/i
            fill(response(actionid, AMIResponseHelper.events_off_response))
          else
            fill(response(actionid, AMIResponseHelper.events_on_response))
          end
        end
      when "ping"
        fill(response(actionid, AMIResponseHelper.ping_response))
      else
        raise ArgumentError, "Unknown action #{args['action']}"
      end
  end

  private
  
  def response(action_id, args = {})
    resp = []
    resp << "Response: #{args.delete('Response')}" if args['Response']
    resp << "Event: #{args.delete('Event')}" if args['Event']
    resp << "ActionID: #{action_id}"
    resp << "Message: #{args.delete('Message')}" if args['Message']
    args.inject(resp) do |accum, pair|
      accum << "#{pair[0]}: #{pair[1]}"
    end
    resp.join("\r\n")
  end
  
  def fill(line, blanks=2)
    @buffer += line
    @buffer += "\r\n" * blanks
  end
  
  def prompt;   "Asterisk Call Manager/1.0" end
  def username; "admin"                     end
  def password; "password"                  end
end
