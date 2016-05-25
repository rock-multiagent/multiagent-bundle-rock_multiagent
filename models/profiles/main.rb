require 'rock_multiagent/models/compositions/message_transport.rb'

module RockMultiagent
    profile 'Profile' do
        define 'message_transport_service', Compositions::MessageTransportService
    end
end
