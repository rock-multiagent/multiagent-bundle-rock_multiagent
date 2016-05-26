require 'rock_multiagent/models/compositions/message_transport'

module RockMultiagent
    profile 'Profile' do
        define 'fipa_message_transport_service', Compositions::FIPAMessageTransportService
    end
end
