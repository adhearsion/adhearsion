require File.join(File.dirname(__FILE__), 'config_generator')

module Adhearsion
  module VoIP
    module Asterisk
      module ConfigFileGenerators
        class Voicemail < AsteriskConfigGenerator

          DEFAULT_GENERAL_SECTION = {
            :format => :wav
          }

          # Don't worry. These will be overridable soon.
          STATIC_ZONEMESSAGES_CONTEXT = %{
            [zonemessages]
            eastern=America/New_York|'vm-received' Q 'digits/at' IMp
            central=America/Chicago|'vm-received' Q 'digits/at' IMp
            central24=America/Chicago|'vm-received' q 'digits/at' H N 'hours'
            military=Zulu|'vm-received' q 'digits/at' H N 'hours' 'phonetic/z_p'
            european=Europe/Copenhagen|'vm-received' a d b 'digits/at' HM
          }.unindent

          attr_reader :properties, :context_definitions
          def initialize
            @properties = DEFAULT_GENERAL_SECTION.clone
            @mailboxes  = {}
            @context_definitions = []
            super
          end

          def context(name)
            raise ArgumentError, "Name cannot be 'general'!" if name.to_s.downcase == 'general'
            raise ArgumentError, "A name can only be characters, numbers, and underscores!" if name.to_s !~ /^[\w_]+$/

            ContextDefinition.new(name).tap do |context_definition|
              yield context_definition
              context_definitions << context_definition
            end
          end

          def greeting_maximum(seconds)
            int "maxgreet" => seconds
          end

          def execute_on_pin_change(command)
            string "externpass" => command
          end

          def recordings
            @recordings ||= RecordingDefinition.new
            yield @recordings if block_given?
            @recordings
          end

          def emails
            @emails ||= EmailDefinition.new
            if block_given?
              yield @emails
            else
              @emails
            end
          end

          def to_s
            email_properties = @emails ? @emails.properties : {}
            AsteriskConfigGenerator.warning_message +
            "[general]\n" +
            properties.merge(email_properties).map { |(key,value)| "#{key}=#{value}" }.sort.join("\n") + "\n\n" +
            STATIC_ZONEMESSAGES_CONTEXT +
            context_definitions.map(&:to_s).join("\n\n")
          end

          private

          class ContextDefinition < AsteriskConfigGenerator

            attr_reader :mailboxes
            def initialize(name)
              @name      = name
              @mailboxes = []
              super()
            end

            # TODO: This will hold a lot of the methods from the [general] section!

            def to_s
              (%W[[#@name]] + mailboxes.map(&:to_s)).join "\n"
            end

            def mailbox(mailbox_number)
              box = MailboxDefinition.new(mailbox_number)
              yield box
              mailboxes << box
            end

            private

            def mailbox_entry(options)
              MailboxDefinition.new.tap do |mailbox|
                yield mailbox if block_given?
                mailboxes << definition
              end
            end

            class MailboxDefinition

              attr_reader :mailbox_number
              def initialize(mailbox_number)
                check_numeric mailbox_number
                @mailbox_number = mailbox_number
                @definition = {}
                super()
              end

              def pin_number(number)
                check_numeric number
                @definition[:pin_number] = number
              end

              def name(str)
                @definition[:name] = str
              end

              def email(str)
                @definition[:email] = str
              end

              def to_hash
                @definition
              end

              def to_s
                %(#{mailbox_number} => #{@definition[:pin_number]},#{@definition[:name]},#{@definition[:email]})[/^(.+?),*$/,1]
              end

              private

              def check_numeric(number)
                raise ArgumentError, number.inspect + " is not numeric!" unless number.to_s =~ /^\d+$/
              end

            end
          end

          class EmailDefinition < AsteriskConfigGenerator
            EMAIL_VARIABLE_CONVENIENCES = {
              :name             => '${VM_NAME}',
              :duration         => '${VM_DUR}',
              :message_number   => '${VM_MSGNUM}',
              :mailbox          => '${VM_MAILBOX}',
              :caller_id        => '${VM_CALLERID}',
              :date             => '${VM_DATE}',
              :caller_id_number => '${VM_CIDNUM}',
              :caller_id_name   => '${VM_CIDNAME}'
            }

            attr_reader :properties
            def initialize
              @properties = {}
              super
            end

            def [](email_variable)
              if EMAIL_VARIABLE_CONVENIENCES.has_key? email_variable
                EMAIL_VARIABLE_CONVENIENCES[email_variable]
              else
                raise ArgumentError, "Unrecognized variable #{email_variable.inspect}"
              end
            end

            def disable!
              raise NotImpementedError
            end

            def from(options)
              name, email = options.values_at :name, :email
              string :serveremail => email
              string :fromstring  => name
            end

            def attach_recordings(true_or_false)
              boolean :attach => true_or_false
            end

            def attach_recordings?
              properties[:attach] == 'yes'
            end

            def body(str)
              str = str.gsub("\r", '').gsub("\n", '\n')
              if str.length > 512
                raise ArgumentError, "Asterisk has an email body limit of 512 characters! Your body is too long!\n" +
                ("-" * 10) + "\n" + str
              end
              string :emailbody => str
            end

            def subject(str)
              string :emailsubject => str
            end

            def command(cmd)
              string :mailcmd => cmd
            end

          end

          class RecordingDefinition < AsteriskConfigGenerator

            attr_reader :properties
            def initialize
              @properties = {}
              super
            end

            def format(symbol)
              one_of [:gsm, :wav49, :wav], :format => symbol
            end

            def allowed_length(seconds)
              case seconds
                when Fixnum
                  int :maxmessage => "value"
                when Range
                  int :minmessage => seconds.first
                  int :maxmessage => seconds.last
                else
                  raise ArgumentError, "Argument must be a Fixnum or Range!"
              end
            end

            def maximum_silence(seconds)
              int :maxsilence => seconds
            end
          end
        end
      end
    end
  end
end
