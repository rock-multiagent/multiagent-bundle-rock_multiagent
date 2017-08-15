using_task_library 'fipa_services'

module RockMultiagent
    module Compositions
        class Probe < Syskit::Composition
            # to make the composition executable
            add FipaServices::MessageTransportTask, :as => 'mts'

            # Relevant when using signalling only
            # event :probing do
            #     puts "Creating event"
            #     emit :probing
            # end
            #
            event :probing
            event :probing_success

            on :probing do |event|
                # Context is an array of arguments given to the event
                Robot.info "#{self} received event :probing with context #{event.context}"
                emit :probing_success
            end
        end
    end # Compositions
end # RockMultiagent
