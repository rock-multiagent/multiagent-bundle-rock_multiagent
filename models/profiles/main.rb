require 'rock_multiagent/config/deployments'
require 'rock_multiagent/models/compositions'

module RockMultiagent
    profile 'Profile' do
        define 'fipa_message_transport', FipaServices::MessageTransportTask.
            with_local_receivers('sensors','telemetry').
            prefer_deployed_tasks(/"#{Roby.app.robot_name}__message_transport_task"/)

        define 'telemetry_publisher', Compositions::TelemetryPublisher.
            use('message_transport' => fipa_message_transport_def)
        define 'telemetry_subscriber', Compositions::TelemetrySubscriber.
            use('message_transport' => fipa_message_transport_def)
    end
end
