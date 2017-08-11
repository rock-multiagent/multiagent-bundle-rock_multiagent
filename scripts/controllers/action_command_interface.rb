require 'fipa-message'
require 'yaml'

module RockMultiagent
    class ActionCommandInterface
        attr_reader :robot
        attr_reader :robot_name
        attr_accessor :mts_task
        attr_accessor :letter_reader

        def initialize(robot, robot_name, mts_task)
            @robot.info "Initializing #{self.class} with #{robot_name} and #{mts_task.name}" if @robot
            @robot = robot
            @robot_name = robot_name
            @mts_task = mts_task
            @letter_reader = mts_task.port(robot_name).reader
            @letter_writer = mts_task.letters.writer
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

        def request_action(receiver, action_name, arguments)
            msg = FIPA::ACLMessage.new
            msg.setPerformative :request
            msg.setSender FIPA::AgentId.new(@robot_name)
            msg.addReceiver FIPA::AgentId.new(receiver)

            msg.setLanguage 'syskit'
            msg.setProtocol 'request'
            msg.setContent "ACTION #{action_name} EXEC #{arguments.to_yaml}"

            @robot.info "Request action: #{receiver} action: #{action_name} #{arguments}" if @robot
            letter = FIPA::ACLEnvelope.new
            letter.insert(msg, FIPARepresentation::BITEFFICIENT)

            @letter_writer.write letter
            letter
        end

        def handle_letter(letter)
            @robot.info "Handling received message" if @robot
            msg = letter.getACLMessage
            @robot.info "protocol: '#{msg.getProtocol}', language '#{msg.getLanguage}', content '#{msg.getContent}'" if @robot
            if msg.getPerformative == :request
                if msg.getLanguage == 'syskit'
                    @robot.info "handle syskit request: #{msg.getContent}" if @robot
                    execute_action_request msg.getContent
                end
            end
        end

        # Execute an action request define by the 
        # syskit content language
        # ACTION <action_name> EXEC <argument list as yaml>
        def execute_action_request(content)
            @robot.info "execute action request: #{content}" if @robot

            # /m as multiline matching
            puts content.match(/^ACTION(.*)(EXEC|HALT|PAUSE)(.*)/m)
            action_name = $1.strip
            action_type = $2.strip
            action_arguments = nil
            if $3
                action_arguments = YAML.load $3.strip
            end
            execute_action(action_name, action_arguments)
        end

        def execute_action(action_name, arguments)
            @robot.info "Execute #{action_name}! #{arguments}"
            @robot.send("#{action_name}!", arguments) if @robot
        end
    end
end


#action_cmd = RockMultiagent::ActionCommandInterface.new(nil, "sherpa_tt", nil)
#arguments = {:x => 0, :y => 0}
#letter = action_cmd.request_action("sherpa_tt", "move_to", arguments)
#action_cmd.handle_letter letter
#action_cmd.execute_action_request("ACTION move_to EXEC #{arguments.to_yaml}")
#action_cmd.execute_action("move_to","x 0 y 0 z 0")

