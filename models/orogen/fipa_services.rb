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
        each_data_service do |srv|
            if srv.fullfills?(RockMultiagent::FIPAMessageProviderSrv)
                is_local = true
                if !orocos_task.has_port?(srv.name) && !orocos_task.addReceiver(srv.name, is_local)
                    ::Robot.warn "FipaServices::MessageTransportTask: Failed to add receiver port '#{srv.name}'"
                    return false
                end
            end
        end
    end

    # Add dynamic ports -- this is mainly necessary to support and use the
    # modelling tools in syskit, e.g.
    #     FipaServices::MessageTransportTask.with_local_receivers("default")
    # will create a composition of type
    #     RockMultiagent::Compositions::FIPAMessageTransportService
    # with the corresponding local receiver (output)ports as configured in the
    # 'default' section of an existing FipaServices::MessageTransportTask
    # configuration
    #
    def self.with_local_receivers(*conf_names)
        receiver_names = get_local_receivers(conf_names)

        ::Robot.info "Configuration of #{self} with local receivers: #{receiver_names} -- #{__FILE__}"

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
    def self.get_local_receivers(*conf_names)
        config_file = FipaServices::MessageTransportTask.configuration_manager.existing_configuration_file
        Orocos.conf.load_file(config_file)
        conf = Orocos.conf.resolve("fipa_services::MessageTransportTask", *conf_names, true)
        local_receivers = conf['local_receivers'] || []

        # Prefix all local receivers with the robot name
        regexp = Regexp.new(Roby.app.robot_name)
        local_receivers = local_receivers.map do |receiver_name|
            if !regexp.match(receiver_name)
                "#{Roby.app.robot_name}-#{receiver_name}"
            else
                receiver_name
            end
        end

        # Robot name should always be available as communication channel
        local_receivers << Roby.app.robot_name
        local_receivers.uniq
    end
end
