methods_for :rpc do

  # Simply create proxy methods for the high-level AMI methods

  [:send_action, :introduce, :originate, :call_into_context, :call_and_exec, :ping].each do |method_name|
    define_method(method_name) do |*args|
      if Asterisk.manager_interface
        Asterisk.manager_interface.send(method_name, *args)
      else
        logger.error "AMI has not been enabled in startup.rb!"
      end
    end
  end

end