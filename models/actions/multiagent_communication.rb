require 'rock_multiagent/models/compositions/message_transport'
module Rock
    module Multiagent
        module Actions
            class Communication < Roby::Actions::Interface

                describe("Start the message transport service")
                .returns(Compositions::MessageTransportService)
                def message_transport_service
                    ::Rock::Multiagent::Compositions::MessageTransportService
                end
            end
        end
    end
end
