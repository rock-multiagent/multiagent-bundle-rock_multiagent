using_task_library 'telemetry_provider'

require 'rock_multiagent/models/compositions/message_transport'

module RockMultiagent
    module Compositions
        # Telemetry subscriber will listen to publishers sending to all
        # receivers suffixed by -telemetry
        class TelemetryPublisher < Syskit::Composition
            add FIPAMessageTransportService, as: 'message_transport'

            add TelemetryProvider::FIPAPublisher  , as: "publisher"
            add TelemetryProvider::Multiplexer, as: "multiplexer"

            publisher_child.fipa_message_port.connect_to message_transport_child.letters_port
        end

        class TelemetrySubscriber < Syskit::Composition
            add FIPAMessageTransportService, as: 'message_transport'

            add TelemetryProvider::FIPASubscriber , as: "subscriber"
            add TelemetryProvider::Demultiplexer, as: "demultiplexer"

            subscriber_child.telemetry_package_port.connect_to \
                demultiplexer_child.telemetry_package_port

            def self.instanciate(*args)
                root = super
                root.message_transport_child.each_data_service do |data_service|
                    if data_service.model.fullfills?(RockMultiagent::FIPAMessageProviderSrv)
                        out_port = data_service.fipa_out_port
                        if data_service.name =~ /#{Roby.app.robot_name}-telemetry/
                            out_port.connect_to \
                               root.subscriber_child.fipa_message_port
                        end
                    end
                end
                root
            end
        end
    end
end
