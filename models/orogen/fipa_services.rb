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
                if !orocos_task.addReceiver(srv.name, is_local)
                    raise RuntimeError, "FipaServices::MessageTransportTask: Failed to add a receiver name #{srv.name}"
                end
            end
        end
    end

    # Add dynamic ports -- this is mainly necessary to support and use the
    # modelling tools in syskit, e.g.
    #     FipaServices::MessageTransportTask.with_local_receivers(["my-robot"])
    # will create a composition of type
    #     RockMultiagent::Compositions::FIPAMessageTransportService
    # with the corresponding local receiver (output)ports
    #
    def self.with_local_receivers(receiver_names = Array.new)
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
end
