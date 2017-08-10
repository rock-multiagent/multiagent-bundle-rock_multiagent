require 'orocos'
require_relative 'action_command_interface'

begin 
    $action_cmd = nil
    Roby.every(1) do

        if !$action_cmd
            begin
                Robot.info "RockMultiagent::Controller: looking for mts task"
                mts = Orocos::TaskContext.get_provides "fipa_services::MessageTransportTask"
                Robot.info "RockMultiagent::Controller: found #{mts.name}"
                if mts
                    Robot.info "RockMultiagent::Controller: setting action_cmd interface"
                    $action_cmd = RockMultiagent::ActionCommandInterface.new(Robot, Roby.app.robot_name, mts)
                end
            rescue Orocos::NotFound => e
                Robot.info "RockMultiagent::Controller: could not create ActionCommandInterface: #{e}"
            end
        else
            begin
                $action_cmd.trigger
            rescue Exception => e
                Robot.warn "RockMultiagent::Controller: triggering of action command interface failed: #{e}"
            end
        end
    end
rescue Exception => e
    Robot.warn "#{e}"
end

