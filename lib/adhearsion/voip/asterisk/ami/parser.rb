require 'drb'
require 'adhearsion/voip/asterisk/ami/machine'

module Adhearsion
	module VoIP
		module Asterisk
			class AMI
				class Packet < Hash
					def error?
            false
					end
					
					def raw?
            false
				  end
				  
				  def is_event?
            false
			    end
			    
			    # Return the hash, without the internal Action ID
					def body
						returning clone do |packet|
						  packet.delete 'ActionID'
  					end
					end
					
					def message
						self['Message']
					end
				end

				class EventPacket < Packet
					attr_accessor :event
					def initialize(event)
					  @event = event
						super(false)
					end
					
					def is_event?
            true
				  end
				end
				
				class ErrorPacket < Packet
				  def error?
				    true
			    end
			  end
				
				class FollowsPacket < Packet
				  def raw?
				    true
				  end
			  end
			  
			  class ImmediatePacket < Packet
				  def raw?
				    true
				  end
		    end
		    
				class Parser
          # Size of the scanner buffer
					BUFSIZE = 1024
          
          attr_accessor :logger
          attr_reader :events

          def initialize
            self.extend Machine
            
            # Add the variables and accessors used for marking seen data
  					%w(event key value version).each do |name|
  						instance_eval <<-STR
  							class << self
  								send(:attr_accessor, "__ragel_mark_#{name}")
  								send(:attr_accessor, "__ragel_#{name}")
  							end
  							send("__ragel_mark_#{name}=", 0)
  							send("__ragel_#{name}=", nil)
  						STR
  					end

  					%w(raw).each do |name|
  						instance_eval <<-STR
  							class << self
  								send(:attr_accessor, "__ragel_mark_#{name}")
  								send(:attr_accessor, "__ragel_#{name}")
  							end
  							send("__ragel_mark_#{name}=", 0)
  							send("__ragel_#{name}=", [])
  						STR
  					end
						@signal         = ConditionVariable.new
						@mutex          = Mutex.new
						@events         = Queue.new
						@current_packet = nil
            @logger         = Logger.new STDOUT
					end

					private
					
					# Set the starting marker position
					def mark(name)
						send("__ragel_mark_#{name}=", @__ragel_p)
					end

          # Set the starting marker position for capturing raw data in an array
					def mark_array(name)
						send("__ragel_mark_#{name}=", @__ragel_p)
					end

          # Capture the marked data from the marker to the current position
					def set(name)
						mark = send("__ragel_mark_#{name}")
						return if @__ragel_p == mark
						send("__ragel_#{name}=", @__ragel_data[mark..@__ragel_p-1])
						send("__ragel_mark_#{name}=", 0)
					end

          # Insert the data marked from the marker to the current position in the array
					def insert(name)
						mark = send("__ragel_mark_#{name}")
						return if @__ragel_p == mark
						var = send("__ragel_#{name}")
						var << @__ragel_data[mark..@__ragel_p-1]
						send("__ragel_#{name}=", var)
					end
		
		      # Capture a key / value pair in a response packet
					def pair
						@current_packet[@__ragel_key] = @__ragel_value
					end
		
		      # This method completes a packet. Add the current raw data to it if it
		      # is an immediate or raw response packet. If it has an action ID, it belongs
		      # to a command, so signal any waiters. If it does not, it is an asynchronous
		      # event, so add it to the event queue.
					def packet
						return if not @current_packet
 						@current_packet[:raw] = @__ragel_raw.join("\n") if @current_packet.raw?
            action_id = nil
            if not @current_packet.is_event? or @current_packet['ActionID']
						  action_id = @current_packet['ActionID'] || 0
            end
						logger.debug "Packet end: #{@__ragel_p}, #{@current_packet.class}, #{action_id.inspect}"
						logger.debug "=====>#{@current_packet[:raw]}<=====" if @current_packet.raw?
            if action_id
              # Packets with IDs are associated with the action of the same ID
              action = Actions::Action[action_id]
  						action << @current_packet
            else
              # Asynchronous events without IDs go into the event queue
              @events.push(@current_packet)
            end
						@signal.broadcast
						@current_packet = nil
						@__ragel_raw = []
					end
					
					public
					# Wait for any packets (including events) that have the specified Action ID.
					# Do not stop waiting until all of the packets for the specified Action ID
					# have been seen.
					def wait(action)
						logger.debug "Waiting for #{action.action_id.inspect}"
						@mutex.synchronize do
							loop do
                action.check_error!
                return action.packets! if action.done?
								@signal.wait(@mutex)
							end
						end
					end

          # Receive an event packet from the event packet queue.
					def receive
						@events.pop
					end

          # Stop the scanner.
          def stop
            @mutex.synchronize do
              @thread.kill if @thread
            end
            @thread = nil
          end
          
          # Run the scanner on the specified socket.
					def run(socket)
						@__ragel_eof = nil
						@__ragel_data = " " * BUFSIZE
            @__ragel_raw = []

						ragel_init

            # Synchronize, so we can wait for the command prompt before the
            # scanner actually starts.
						@mutex.synchronize do
							@thread = Thread.new do
								have = 0
								loop do
								  # Grab as many bytes as we can for now.
									space = BUFSIZE - have
									raise RuntimeError, "No space" if space == 0
									bytes = 0
									begin
                    socket.synchronize do
											bytes = socket.read_nonblock(space)
                    end
									rescue Errno::EAGAIN
                    # Nothing available. Try again.
										retry
									rescue EOFError
									  # Socket closed. We are done.
										break
									end

                  # Adjust the pointers.
									logger.debug "Got #{bytes.length} bytes, #{bytes.inspect}"
									@__ragel_p = have
									@__ragel_data[@__ragel_p..@__ragel_p + bytes.size - 1] = bytes
									@__ragel_pe = @__ragel_p + bytes.size
									logger.debug "P: #{@__ragel_p} PE: #{@__ragel_pe}"

                  # Run the scanner state machine.
									@mutex.synchronize do
										ragel_exec
									end
                  
									if @__ragel_tokstart.nil? or @__ragel_tokstart == 0
										have = 0
									else
                    # Slide the window.
										have = @__ragel_pe - @__ragel_tokstart
										logger.debug "Sliding #{have} from #{@__ragel_tokstart} to 0 (tokend: #{@__ragel_tokend.inspect})"
										@__ragel_data[0..have-1] = @__ragel_data[@__ragel_tokstart..@__ragel_tokstart + have - 1]
										@__ragel_tokend -= @__ragel_tokstart if @__ragel_tokend
										@__ragel_tokstart = 0
										logger.debug "Data: #{@__ragel_data[0..have-1].inspect}"
									end
								end
								@thread = nil
							end
							# Wait for the command prompt.
							while @__ragel_version.blank?
								@signal.wait(@mutex)
							end
						end
						# Return the version number.
						@__ragel_version
					end
				end
      end
		end
	end
end
