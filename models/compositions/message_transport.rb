using_task_library 'fipa_services'

module Rock
    module Multiagent
        module Compositions
            class MessageTransportService < Syskit::Composition
                add FipaServices::MessageTransportTask, :as => 'message_transport'
            end
        end
    end
end
