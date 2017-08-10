require 'rock_multiagent/scripts/controllers/action_command_interface'

module RockMultiagent
    module Tasks
        class SingleRobotCommand < Roby::Task
            argument :receiver, :default => nil
            argument :action_name, :default => nil
            argument :argument_hash, :default => Hash.new

            attr_reader :action_cmd
            attr_reader :mts


            def initialize(arguments = Hash.new)
                super(arguments)

                begin
                    mts = Orocos::TaskContext.get_provides "fipa_services::MessageTransportTask"
                    @action_cmd = RockMultiagent::ActionCommandInterface.new(Robot, Roby.app.robot_name, mts)
                rescue Orocos::NotFound => e
                    Robot.warn "RockMultiagent::Tasks::ActionCommand: failed to initialize the action command interface: #{e}"
                    emit :failed
                end
            end


            on :start do |event|
                begin
                    action_cmd.request_action(receiver, action_name,argument_hash)
                rescue Exception => e
                    Robot.warn "RockMultiagent::Tasks::ActionCommand: failed to request action: #{e}"
                    emit :failed
                end
            end
        end
    end
end
