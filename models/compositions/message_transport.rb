using_task_library 'fipa_services'
require 'rock_multiagent/models/services'

module RockMultiagent
    module Compositions
        class FIPAMessageTransportService < Syskit::Composition
            add FipaServices::MessageTransportTask, as: 'message_transport'

            export message_transport_child.letters_port, as: 'letters'
        end
    end
end
