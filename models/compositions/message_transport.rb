using_task_library 'fipa_services'
require 'rock_multiagent/models/services'

module RockMultiagent
    module Compositions

        # This composition will be use to handle dynamic services
        # see models/orogen/fipa_service.rb and 
        # rock-robotics.org/master/ for more information on dynamic services
        class FIPAMessageTransportService < Syskit::Composition
            add FipaServices::MessageTransportTask, as: 'message_transport'

            export message_transport_child.letters_port, as: 'letters'
        end
    end
end
