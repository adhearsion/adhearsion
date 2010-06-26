require 'md5'
require 'open-uri'

SANDBOX_VERSION = 1.0

initialization do
  # We shouldn't start initializing until after the AGI server has initialized.
  Events.register_callback(:after_initialized) do

    config = if COMPONENTS.sandbox.has_key? "connect_to"
      {"connect_to" => COMPONENTS.sandbox["connect_to"]}
    else
      begin
        yaml_data = open("http://sandbox.adhearsion.com/component/#{SANDBOX_VERSION}").read
        YAML.load yaml_data
      rescue SocketError
        ahn_log.sandbox.error "Could not connect to the sandbox server! Skipping sandbox initialization!"
        next
      rescue => e
        ahn_log.sandbox.error "COULD NOT RETRIEVE SANDBOX CONNECTION INFORMATION! Not initializing sandbox component!"
        next
      end
    end

    begin
      # The "connect_to" key is what this version supports
      if config.kind_of?(Hash) && config.has_key?("connect_to")
        config = config['connect_to']

        host, port = config.values_at "host", "port"

        username, password = COMPONENTS.sandbox["username"].to_s, COMPONENTS.sandbox["password"].to_s

        if username.blank? || password.blank? || username == "user123"
          ahn_log.sandbox.error "You must specify your username and password in this component's config file!"
          next
        end

        # Part of the AGI-superset protocol we use to log in.
        identifying_hash = MD5.md5(username + ":" + password).to_s

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
              response = socket.gets
              unless response
                next
              end
              response.chomp!
              case response
                when "authentication accepted"
                  ahn_log.sandbox "Authentication accepted"

                  start_signal = socket.gets
                  next unless start_signal
                  start_signal.chomp!

                  if start_signal
                    ahn_log.sandbox "Incoming call from remote sandbox server!"
                    begin
                      Adhearsion::Initializer::AsteriskInitializer.agi_server.server.serve(socket)
                    rescue => e
                      ahn_log.error "Non-fatal exception in the AGI server: #{e.inspect} \n" + e.backtrace.join("\n")
                    ensure
                      socket.close rescue nil
                    end
                    ahn_log.sandbox "AGI server finished serving call. Reconnecting to sandbox."
                  else
                    ahn_log.sandbox "Remote Asterisk server received no call. Reconnecting..."
                  end
                when "authentication failed"
                  ahn_log.sandbox.error "Your username or password is invalid! Skipping sandbox initialization..."
                  break
                when /^wait (\d+)$/
                  sleep response[/^wait (\d+)$/,1].to_i
                else
                  ahn_log.sandbox.error "Invalid login acknowledgement! Skipping sandbox initialization!"
                  break
              end
            rescue Errno::ECONNREFUSED
              ahn_log.sandbox.error "Could not connect to the sandbox server! Sandbox component stopping..."
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
