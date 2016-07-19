require 'rock_multiagent/models/actions/multiagent_communication'
require 'rock_multiagent/models/profiles'
require 'rock_multiagent/models/tasks'

# The main planner. A planner of this model is automatically added in the
# Interface planner list.
module RockMultiagent
    module Actions
        class Common < Roby::Actions::Interface
            use_profile RockMultiagent::Profile
            use_library RockMultiagent::Actions::Communication

            # Adding requirement handling here to coordinate between multiple supervisions
            # and via the plan manager - possibly use alternative interface which relies
            # on a negotiating access
            #
            # Example:
            #    Robot.add_device_requirement! :device_name => 'cam_body_right'
            #
            describe("Device control action in order to start/stop a specific device and connect it to the telemetry provider, so that sensor data can be forwarded to external systems").
                required_arg("name", "Device name").
                optional_arg("type", "Device type - to determine which port to use").
                optional_arg("control", "One of :start or :stop - default is start")
            def device_control(arguments = Hash.new)
                device_control = DeviceControl.new arguments
                provider = device_control.depends_on(TelemetryProvider::Task, :role => 'telemetry_provider')
                device_control.should_start_after provider.start_event
                device_control
            end

            describe("Add a requirements for a specific device from an external entity").
                required_arg("device_name","Device that is required by an external entity")
            def add_device_requirement(arguments = Hash.new)
                AddExternalDependency.new arguments
            end

            describe("Remove a device requirement from an external entity").
                required_arg("device_name", "Device that is not required any more by the external entity")
            def remove_device_requirement(arguments = Hash.new)
                RemoveExternalDependency.new arguments
            end

            describe("Idle command to run a command for a certain time frame").
                optional_arg("duration", "time in s this task should run for")
            def idle(arguments = Hash.new)
                task = Idle.new arguments
                task
            end

        end
    end
end

