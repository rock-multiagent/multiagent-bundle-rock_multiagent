# Drafting to handle external dependencies
class ExternalDependencyTracker
    @@dependencies = Hash.new

    def self.add_dependency(task)
        if not Roby.plan.mission?(task)
            instance = Roby.orocos_engine.add_mission(task)
            @@dependencies[task] = instance
        end
    end

    def self.remove_dependency(task)
        if Roby.plan.mission?(task)
            remove = true
            instance.orogen_task.each_port do |port|
                remove = remove && !port.connected?
                if not remove
                    Robot.info "ExternalDependencyTracker: '#{task}' not removed since there are still open connections to the task instance"
                    return
                end
            end

            if remove 
                Robot.info "ExternalDependencyTracker: '#{task}' unneeded by external (internal) systems -- can be removed"
                instance = @@dependencies.delete(task)
                Roby.orocos_engine.remove(instance)
            end
        end
    end
end

class AddExternalDependency < Roby::Task
    
    argument :device_name
    # check if the device_name exists
    # ..
    on :start do |context|
        device = device_name
        if device_name.respond_to?(:to_s) 
            begin
                device = Roby.app.orocos_system_model.device_model(device_name.to_s) 
            rescue ArgumentError => e
                Robot.error "Service '#{device_name}' is not a known data device_name model -- #{e}"
                emit :failed
            end
        elsif not defined? device_name 
            Robot.error "Service '#{device_name}' is not a known data device_name model"
            emit :failed
        end

        # Add device_name to mission
        ExternalDependencyTracker.add_dependency(device)
        emit :success
    end
end


class RemoveExternalDependency < Roby::Task
    
    argument :device_name

    on :start do |context|
        device = device_name
        if device_name.respond_to?(:to_s) 
            begin
                device = Roby.app.orocos_system_model.device_model(device_name.to_s) 
            rescue ArgumentError => e
                Robot.error "Service '#{device_name}' is not a known data device_name model -- #{e}"
                emit :failed
            end
        elsif not defined? device_name 
            Robot.error "Service '#{device_name}' is not a known data device_name model"
            emit :failed
        end

        # Remove device_name from plan only if there are not connection any more
        ExternalDependencyTracker.remove_dependency(device)
        emit :success
    end
end
