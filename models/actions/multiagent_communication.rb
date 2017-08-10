require 'rock_multiagent/models/compositions/message_transport'
require 'rock_multiagent/models/tasks/single_robot_command'

module RockMultiagent
    module Actions
        class Communication < Roby::Actions::Interface
            describe("Send an action command to another system").
                required_arg("receiver", "Name of the agent to receive this action command").
                required_arg("action_name", "Name of the action").
                optional_arg("argument_hash", "Hash describing the arguments").
                returns(RockMultiagent::Tasks::SingleRobotCommand)
            def single_robot_command(arguments = Hash.new)
                tasks = RockMultiagent::Tasks::SingleRobotCommand.new arguments
                tasks
            end
        end
    end
end
