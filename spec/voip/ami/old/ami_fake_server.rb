class Responses
  class << self
    KNOWN_RESPONSES = {
      :bad_login_response                   => { "Response" => "Error", "Message" => "Authentication failed" }
      :good_login_response                  => { "Response" => "Success", "Message" => "Authentication accepted" }
      :follows_response                     => { "Response" => "Follows", "Privilege" => "Command" }
      :bad_dbget_response                   => { "Response" => "Error", "Message" => "Database entry not found" }
      :good_dbget_response                  => { "Response" => "Success", "Message" => "Result will follow" }
      :dbput_response                       => { "Response" => "Success", "Message" => "Updated database successfully" }
      :dbget_event_response                 => { "Event" => "DBGetResponse" }
      :queue_status_response                => { "Response" => "Success", "Message" => "Queue status will follow" }
      :queue_status_event_complete_response => { "Event" => "QueueStatusComplete" }
      :queue_status_event_params_response   => { "Event" => "QueueParams", "Queue" => "default", "Max" => 0,
                                                 "Min" => 0, "Holdtime" => 0, "Completed" => 0, "Abandoned" => 0,
                                                 "ServiceLevel" => 0, "ServiceLevelPerf" => 0  }
      :events_on_response                   => { "Response" => "Events On" }
      :events_off_response                  => { "Response" => "Events Off" }
      :ping_response                        => { "Response" => "Pong" }
      :unrecognized_action                  => { "Response" => "Error", "Message" => "Invalid/unknown command" }
    }
  end
  
  
  
  class Recorder
    
    def initialize
      @recorded_actions = []
    end
    
    def method_missing(name)
      super unless KNOWN_RESPONSES.has_key? name
      @recorded_actions << KNOWN_RESPONSES[name]
    end
    
    def responses
      @recorded_actions.map do |action|
        hash_response_to_string action
      end
    end
    
    private
    
    def hash_response_to_string(hash_response)
      hash_response.inject(String.new) do |full_response,(key,value)|
        full_response + "#{key}: #{value}\r\n"
      end
    end
    action.inject(String.new) do |full_response,(key,value)|
      full_response + key + ": " + value + "\r\n"
    end
    
  end
  
end
