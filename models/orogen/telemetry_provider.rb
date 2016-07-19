require 'timeout'

class TelemetryProvider::Task
    def port_name(device_id)
        "#{Roby.app.robot_name}-#{device_id}"
    end

    # Connect to the telemetry provider given an input port
    #
    # device id needs to be a <key> that can be used in order to
    # interprete the data at a receiving end, e.g. to extract data from
    # a 'telemetry_provider/ContainerPackage'
    #
    # 'cam0', 'laserscanner0' ...
    def connect_telemetry_port(output_port, device_id)
        port_name = port_name(device_id)
        ::Robot.info "Creating telemetry port #{port_name} of type #{output_port.orocos_type_name}"
        orogen_task.createTelemetryPort(port_name, output_port.orocos_type_name)
        begin
             output_port.connect_to orogen_task.port(port_name)
        rescue Exception => e
            ::Robot.error "Connecting telemetry port #{port_name} of type #{output_port.orocos_type_name} failed #{e} -- #{e.backtrace}"
            raise "Could not connect device #{device_id} to telemetry_provider. Port #{port_name} is missing -- waited for 60 secs. #{e} -- #{e.backtrace}"
        end
    end

    # Disconnect the telemetry port for a given device id
    def disconnect_telemetry_port(device_id)
        port_name = port_name(device_id)
        orogen_task.removeTelemetryPort(port_name)
    end

    # Setup a number of tasks to connect to the telemetry provider
    def setup_tasks(task_setup = Hash.new)
        task_setup.each do |name, ports|
            setup_task(name, ports)
        end
    end

    # Connect a task to the telemetry provider
    def setup_task(local_task_name, port_names = Hash.new)
        begin
            local_task = Orocos.get local_task_name
            local_task.each_output_port do |p|
                if !port_names || port_names.include?(p.name)
                    connect_telemetry_port(p.name, "#{local_task.name}-#{p.name}")
                end
            end
        rescue Exception => e
            ::Robot.warn "TelemetryProvider::setup_task: could not find running '#{local_task_name}' -- #{__FILE__} - #{e}"
        end
    end
end
