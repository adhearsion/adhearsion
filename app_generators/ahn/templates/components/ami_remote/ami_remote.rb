methods_for :rpc do
  
  # Simply create proxy methods for the high-level AMI methods
  
  [:send_action, :introduce, :originate, :call_into_context, :call_and_exec].each do |method_name|
    define_method(method_name) do |*args|
      if VoIP::Asterisk.manager_interface
        VoIP::Asterisk.manager_interface.send(method_name, *args)
      else
        ahn_log.ami_remote.error "AMI has not been enabled in startup.rb!"
      end
    end
  end
  
end