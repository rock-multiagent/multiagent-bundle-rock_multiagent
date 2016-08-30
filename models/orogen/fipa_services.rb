require 'rock_multiagent/models/compositions/message_transport'
require 'rock_multiagent/models/services'

class FipaServices::MessageTransportTask

    # Declare the 'fipa_message_out' as a dynamic data service
    #
    # The corresponding orogen description must have a dynamic port
    # declaration that matches, e.g.
    # dynamic_output_port /^\w+$/, '/fipa/SerializedLetter'
    #
    # If the name does not have fixed pattern, 'nil' can be used
    dynamic_service RockMultiagent::FIPAMessageProviderSrv, :as => 'fipa_message_out' do
        # This services port will be mapped to a dynamically created 'name'
        # port
        #
        # The 'fipa_out' corresponds to the name of the name of the port in the
        # service definition (data_service_type 'FIPAMessageProviderSrv' do ...)
        provides RockMultiagent::FIPAMessageProviderSrv, 'fipa_out' => name
    end

    def configure
        super
        ::Robot.info "FipaService::MessageTransportTask::configure waiting 5s for propagation of removed services in Avahi ..."
        sleep 5
        ::Robot.info "FipaService::MessageTransportTask::configure completed"
        each_data_service do |srv|
            if srv.fullfills?(RockMultiagent::FIPAMessageProviderSrv)
                local_receivers = orocos_task.local_receivers
                local_receivers << srv.name
                orocos_task.local_receivers = local_receivers
            end
        end
    end

    # Add dynamic ports -- this is mainly necessary to support and use the
    # modelling tools in syskit, e.g.
    #     FipaServices::MessageTransportTask.with_local_receivers("default")
    # will create a composition of type
    #     RockMultiagent::Compositions::FIPAMessageTransportService
    #
    # Adds local receivers port for the constructed names from <robot-name>-<suffix>
    # for the list of receiver suffixes, e.g. .with_local_receivers("sensors","telemetry")
    # will create (together with 'syskit run --robot=myrobotname,myrobottype"')
    # the ports myrobotname-sensors and myrobotname-telemetry
    #
    # If running multiple robots in the same network this fulfills the requirement of 
    # unique naming, which the service registration (Avahi) requires
    #
    def self.with_local_receivers(*receiver_suffixes)
        receiver_names = globally_unique_receivers(receiver_suffixes)

        ::Robot.info "Configuration of #{self} with (globally unique) receivers: #{receiver_names} -- #{__FILE__}"
        task = FipaServices::MessageTransportTask.specialize
        receiver_names.each do |name|
            task.require_dynamic_service 'fipa_message_out', as: name
        end

        RockMultiagent::Compositions::FIPAMessageTransportService.new_submodel do
            overload 'message_transport', task
            receiver_names.each do |name|
                export message_transport_child.find_output_port(name)
                provides RockMultiagent::FIPAMessageProviderSrv, as: name, 'fipa_out' => name
            end
        end
    end

    # Get the local receivers, which is a property of the
    # FipaServices::MessageTransportTask
    #
    # All configured local receiver names will be prefixed with 
    # <robot-name>-
    # so that multiple robots have a set of individual local ports which can be
    # identified by the prefix
    def self.globally_unique_receivers(local_receivers)
        # Prefix all local receivers with the robot name
        regexp = Regexp.new(Roby.app.robot_name)
        global_receivers = local_receivers.map do |receiver_name|
            if !regexp.match(receiver_name)
                "#{Roby.app.robot_name}-#{receiver_name}"
            else
                receiver_name
            end
        end

        # Robot name should always be available as communication channel
        global_receivers << Roby.app.robot_name
        global_receivers.uniq
    end
end
