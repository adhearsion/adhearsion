require 'md5'
require 'open-uri'

SANDBOX_VERSION = 1.0

initialization do
  # We shouldn't start initializing until after the AGI server has initialized.
  Events.register_callback(:after_initialized) do
    ahn_log.sandbox "Fetching sandbox connection information"
    begin
      yaml_data = open("http://sandbox.adhearsion.com/component/#{SANDBOX_VERSION}").read
      config = YAML.load yaml_data
    rescue SocketError
      ahn_log.sandbox.error "Could not connect to the sandbox server! Skipping sandbox initialization!"
      next
    rescue => e
      ahn_log.sandbox.error "COULD NOT RETRIEVE SANDBOX CONNECTION INFORMATION! Not initializing sandbox component!"
    end
    
    begin
      # The "connect_to" key is what this version supports
      if config.kind_of?(Hash) && config.has_key?("connect_to")
        config = config['connect_to']
      
        host, port = config.values_at "host", "port"
      
        ahn_log.sandbox "Connecting to #{host}:#{port}"
        
        username, password = COMPONENTS.sandbox["username"], COMPONENTS.sandbox["password"]
        
        if username.blank? || password.blank? || username == "user123"
          ahn_log.sandbox.error "You must specify your username and password in this component's config file!"
          next
        end
        
        # Part of the AGI-superset protocol we use to log in.
        identifying_hash = MD5.md5(username + ":" + password).to_s
        
        ahn_log.sandbox "Your hash is #{identifying_hash}"
        
        if host.nil? || port.nil?
          ahn_log.sandbox.error "Invalid YAML returned from server! Skipping sandbox initialization!"
          next
        end

        Thread.new do
          loop do
            begin
              ahn_log.sandbox.debug "Establishing outbound AGI socket"
              socket = TCPSocket.new(host, port)
              socket.puts identifying_hash
              case response = socket.gets.chomp
                when "authentication accepted" 
                  ahn_log.sandbox "Authentication accepted"
                  start_signal = socket.gets.chomp
                  if start_signal
                    ahn_log.sandbox "Handing socket off to AGI server."
                    begin
                      Adhearsion::Initializer::AsteriskInitializer.agi_server.server.serve(socket)
                    rescue => e
                      ahn_log.error "Error in the AGI server: #{e.inspect} \n" + e.backtrace.join("\n")
                    end
                    ahn_log.sandbox "AGI server finished serving call. Reconnecting to sandbox."
                  else
                    ahn_log.sandbox "Remote Asterisk server received no call. Reconnecting..."
                  end
                when "authentication failed"
                  break
                when /^wait (\d+)$/
                  sleep response[/^wait (\d+)$/,1].to_i
                else
                  ahn_log.sandbox.error "Invalid login acknowledgement! Skipping sandbox initialization!"
                  break
              end
            rescue Errno::ECONNREFUSED
              ahn_log.sandbox.error "Could not connect to the sandbox reverse-AGI server! Skipping sandbox initialization!"
              break
            rescue => e
              ahn_log.error "Unrecognized error: #{e.inspect} \n" + e.backtrace.join("\n")
            end
          end
        end

      else
        ahn_log.sandbox.error "COULD NOT RETRIEVE SANDBOX CONNECTION INFORMATION! Not initializing sandbox component!"
      end
    rescue => e
      ahn_log.sandbox.error "Encountered an error when connecting to the sandbox! #{e.message}\n" + e.backtrace.join("\n")
    end
  end
end