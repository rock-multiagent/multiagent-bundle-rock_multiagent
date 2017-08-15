require 'roby/task'

module RockMultiagent
    module Tasks
        # Device control allow to start/stop a specific device 
        # and connects it main data port to the telemetry provider
        #
        # In order to select the port to connect we use a fix mapping
        # between the device type and the port, e.g.
        # :camera -> portname: 'frame'
        #
        # The functionality of TelemetryProvider::Task is being extended in
        # models/orogen/telemetry_provider.rb
        #
        class DeviceControl < Roby::Task
            terminates

            @@devices = Hash.new

            # Cache the device task after calling add_mission
            attr_reader :device_task
            attr_reader :initialized

            argument :name
            argument :type, :default => :camera
            argument :control, :default => :start

        #    poll do
        #
        #    if not @initialized
        #            if device_task
                        # Will be set after the actual requirement has been resolved
                        # @device_task = device_task.task
        #                @device_task.start_event.signals_once init_connections_event
        #                Robot.info "DeviceControl: device task has been resolved"
        #
        #                @initialized = true
        #            end
        #        end
        #    end

            on(:start) do |context|

                device_id = arguments[:name].to_s
                control_option = arguments[:control].to_s.downcase.to_sym
                Robot.info "DeviceControl: '#{control_option}' task"

                case control_option
                when :start
                    Robot.info "DeviceControl: starting device"
                    if task = @@devices[device_id] and task.running?
                        Robot.info "DeviceControl: device '#{device_id}' already started"
                        emit :success
                        return
                    else
                        @device_task = Robot.send("#{device_id}_dev!").first
                        @device_task = @device_task.as_service
                        @device_task.start_event.signals_once init_connections_event
                    end
                    # wait in poll block for the task to be resolved 
                when :stop
                    Robot.info "DeviceControl: stopping device"
                    telemetry_provider = child_from_role('telemetry_provider')
                    device_id = arguments[:name]
                    if not @@devices.has_key?(device_id)
                        Robot.warn "DeviceControl: Cannot stop device '#{device_id}', has not been started"
                        emit :success
                    elsif telemetry_provider.disconnect_telemetry_port(device_id)
                        Robot.info "DeviceControl: Successfully removed telemetry port '#{device_id}'"
                        Roby.plan.unmark_mission(@@devices[device_id])
                        @@devices.delete(device_id)

                        # Marking task to be reconfigured before the next startup, e.g. to allow
                        # camera to disconnect and reconnect properly
                        @device_task = Roby.orocos_engine.tasks[device_id]
                        if @device_task
                            Robot.info "DeviceControl: Marking task '#{device_id}' for reconfiguration"
                            @device_task.needs_reconfiguration!
                        else
                            Robot.warn "DeviceControl: Could find task '#{device_id}' to mark for reconfiguration"
                        end

                        # Trigger the removal
                        emit :success
                    else
                        Robot.info "DeviceControl: Failed to remove telemetry port for device '#{device_id}'"
                        emit :failed
                    end
                else
                    Robot.error "DeviceControl: Unknown control option #{control_option}"
                    emit :failed
                end
            end

            on(:success) do |context|
                Robot.info "DeviceControl: control action '#{arguments[:control]}' succeeded for device '#{arguments[:name]}'"
            end

            on(:failed) do |context|
                Robot.error "DeviceControl: control action '#{arguments[:control]}' failed for device '#{arguments[:name]}'"
            end

            # On init the connection to the telemetry provider is created
            # The telemetry provider will add the device package data to its
            # container package which is eventually forwarded to the receiving device
            event :init_connections do |context|
                Robot.info "DeviceControl: initialize connections"
                telemetry_provider = child_from_role('telemetry_provider')

                device_id = arguments[:name]
                device_type = arguments[:type]

                # Cache the task, so that we can refer to it later
                @@devices[device_id] = device_task

                case device_type.to_s.downcase.to_sym
                when :camera
                    port_name = "frame"
                else
                    Robot.error "DeviceControl: Does not support control of device type: #{device_type}"
                    emit :failed
                end
            
                begin 
                    Robot.info "DeviceControl: connect telemetry port"
                    device_port = device_task.orogen_task.port(port_name)
                    telemetry_provider.connect_telemetry_port(device_port,device_id)
                    emit :success
                rescue Exception => e
                    Robot.error "DeviceControl: Failed to connect device '#{device_id}' to telemetry provider #{e} -- #{e.backtrace}"
                    emit :failed
                end
            end

        end
    end
end

    


