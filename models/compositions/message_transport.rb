using_task_library 'fipa_services'

module RockMultiagent
    module Compositions
        class FIPAMessageTransportService < Syskit::Composition
            add FipaServices::MessageTransportTask, as: 'message_transport'
        end
    end
end
