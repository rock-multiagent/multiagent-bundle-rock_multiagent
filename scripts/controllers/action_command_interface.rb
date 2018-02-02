require 'fipa-message'
require 'yaml'
require 'securerandom'

SYSKIT_ACTION_LANGUAGE = "syskit-action-language"
SYSKIT_REQUEST_PROTOCOL = "syskit-request-protocol"
SYSKIT_CONVERSATION_PREFIX = "syskit-conversation-"

module RockMultiagent
    # This action command interface allows to send and receive action command
    # using the distributed communication infrastructure established through the
    # FIPA MessageTransportTasks
    #
    # Example client:
    #
    #    require_relative 'action_command_interface'
    #    require 'orocos'
    #    Orocos.initialize
    #    mts_task = Orocos.name_service.get_provides 'fipa_services::MessageTransportTask'
    #
    #    interface = RockMultiagent::ActionCommandInterface.new(nil, "commander", mts_task)
    #
    #    letter = interface.request_action("myrobot","move_to",{:x => 0, :y => 0}) do do |initial_request, current_response, status|
    #        puts "Update received: #{status}"
    #    end
    #
    #
    #    while true
    #        interface.trigger
    #        status = interface.action_request_status?(letter)
    #        if status.include?("finalized")
    #            break
    #        end
    #        sleep 0.1
    #    end
    #
    class ActionCommandInterface
        attr_reader :robot
        attr_reader :robot_name
        attr_accessor :mts_task
        attr_accessor :letter_reader

        # Map the request (letter) to status
        attr_reader :requests
        # Map job id to letter/conversation
        attr_reader :jobs

        # Callbacks when updates a request are received
        # argument |request, status|
        attr_reader :request_update_callbacks

        # Allow to control the roby interface
        attr_reader :roby_interface

        # List of named instances of the action command interface
        @@named_instances = Hash.new

        def self.named_instances
            @@named_instances
        end

        def self.get_instance(robot, robot_name, mts_task, robot_app = nil)
            if !named_instances.has_key?(robot_name)
                @@named_instances[robot_name] = ActionCommandInterface.new(robot, robot_name, mts_task, robot_app)
            end
            @@named_instances[robot_name]
        end

        def initialize(robot, robot_name, mts_task, roby_app = nil)
            @robot.debug "Initializing #{self.class} with #{robot_name} and #{mts_task.name}" if @robot
            @robot = robot
            @robot_name = robot_name

            if roby_app
                @robot.info "Initializing the roby interface"
                @roby_interface = Roby::Interface::Interface.new(roby_app)
                # kind: success, failed, dropped, finalized
                @roby_interface.on_job_notification do |kind, job_id, job_name|
                    if jobs.has_key?(job_id)
                        send_action_update(job_id, kind)
                    end
                end
            end

            @requests = {}
            @jobs = {}
            @request_update_callbacks = {}

            # Require tasks to perform transport
            @mts_task = mts_task
            @letter_reader = mts_task.port(robot_name).reader :type => :buffer, :size => 25
            @letter_writer = mts_task.letters.writer :type => :buffer, :size => 25
        end

        def trigger
            begin
                if @letter_reader
                    while letter = @letter_reader.read_new
                        handle_letter letter
                    end
                end
            rescue Exception => e
                @robot.warn "Message handling failed: #{e}" if @robot
            end
        end

        # Create a unique conversation id
        def createConversationId
            SYSKIT_CONVERSATION_PREFIX + "-" + Time.now.strftime('%Y%m%d_%H%M%S:%N') + "-" + SecureRandom.uuid
        end

        # Request receiver to perform an action
        # If using the block, then this will be triggered upon an incoming
        # response for this particular request
        #
        # request_action(...) do |initial_request, response, status|
        #  ...
        # end
        #
        # The action request will be encoded as FIPA message and forwared to the
        # receiver
        def request_action(receiver, action_name, arguments, &block)
            msg = FIPA::ACLMessage.new
            msg.setPerformative :request
            msg.setSender FIPA::AgentId.new(@robot_name)
            msg.addReceiver FIPA::AgentId.new(receiver)

            msg.setLanguage SYSKIT_ACTION_LANGUAGE
            msg.setProtocol SYSKIT_REQUEST_PROTOCOL
            msg.setConversationID createConversationId()
            msg.setContent "ACTION #{action_name} EXEC #{arguments.to_yaml}"

            @robot.debug "Request action: #{receiver} action: #{action_name} #{arguments}" if @robot
            letter = FIPA::ACLEnvelope.new
            letter.insert(msg, FIPARepresentation::BITEFFICIENT)

            @letter_writer.write letter

            # Update job status
            @requests[letter] = ["requested"]
            if block_given?
                @request_update_callbacks[letter] = block
            end
            letter
        end

        # Retrieve the known action request status as list of
        # subsequent stati events
        def action_request_status?(letter)
            @requests[letter]
        end

        def get_request_by_conversation_id(conversation_id)
            @requests.each do |request, status|
                available_id = request.getACLMessage.getConversationID
                if  available_id == conversation_id
                    return request
                end
            end
            raise ArgumentError, "#{self}: failed to identify request for conversation: #{conversation_id}"
        end

        # Handle a received letter and process either an action request or an
        # action update
        def handle_letter(letter)
            msg = letter.getACLMessage
            @robot.info "Received message: sender: #{msg.getSender.getName}, protocol: '#{msg.getProtocol}', language '#{msg.getLanguage}', conversation id: '#{msg.getConversationID}', content '#{msg.getContent}'" if @robot

            if msg.getPerformative == :request
                if msg.getLanguage == SYSKIT_ACTION_LANGUAGE
                    @robot.info "Handling incoming action request: #{msg.getContent}" if @robot
                    job_id = execute_action_request(msg.getContent)
                    @jobs[job_id] = letter
                end
            elsif msg.getPerformative == :inform
                if msg.getLanguage == SYSKIT_ACTION_LANGUAGE
                    @robot.info "Handling incoming action update: #{msg.getContent}" if @robot

                    # Match job_id to request using the conversation
                    # id
                    job_id, status = get_job_status(msg.getContent)
                    request = get_request_by_conversation_id(msg.getConversationID)
                    @jobs[job_id] = request
                    @requests[request] << status

                    if block = request_update_callbacks[request]
                        block.call request,letter,status
                    end

                end
            end
        end

        # Extract job id and status from an incoming update message
        def get_job_status(content)
            # /m as multiline matching
            content.match(/^ACTION(.*)STATUS(.*)/m)
            job_id = $1.strip
            status = $2.strip
            [job_id, status]
        end

        # Execute an action request defined by the
        # syskit content language
        # ACTION <action_name> EXEC <argument list as yaml>
        # @returns the job id
        def execute_action_request(content)
            @robot.debug "execute action request: #{content}" if @robot

            # /m as multiline matching
            content.match(/^ACTION(.*)(EXEC|HALT|PAUSE)(.*)/m)
            action_name = $1.strip
            action_type = $2.strip
            action_arguments = nil
            if $3
                action_arguments = YAML.load $3.strip
            end
            execute_action(action_name, action_arguments)
        end

        # Execute and action using the roby action interface
        def execute_action(action_name, arguments)
            @robot.debug "Execute #{action_name}! #{arguments}"
            if @roby_interface
                return @roby_interface.start_job(action_name, arguments)
            else
                raise ArgumentError, "#{self}: the roby interface has not been initialized. " \
                    "Make sure you are requesting action execution on the robot (client)"
            end
        end


        # Create an update response for a request action
        def send_action_update(job_id, status)
            @robot.debug "Preparing sending a job update #{job_id}:#{status}" if @robot
            received_request = @jobs[job_id]
            @requests[received_request] = status

            msg = FIPA::ACLMessage.new
            msg.setPerformative :inform
            msg.setSender FIPA::AgentId.new(robot_name)
            request_msg = received_request.getACLMessage
            receiver = request_msg.getSender
            msg.addReceiver receiver

            msg.setLanguage SYSKIT_ACTION_LANGUAGE
            msg.setProtocol SYSKIT_REQUEST_PROTOCOL
            msg.setConversationID request_msg.getConversationID
            msg.setContent "ACTION #{job_id} STATUS #{status}"

            @robot.debug "Update action: #{receiver.getName} job_id: #{job_id} status: #{status}" if @robot
            letter = FIPA::ACLEnvelope.new
            letter.insert(msg, FIPARepresentation::BITEFFICIENT)

            @letter_writer.write letter
            letter
        end
    end
end


