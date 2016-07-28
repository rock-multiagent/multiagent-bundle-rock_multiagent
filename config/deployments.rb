using_task_library 'fipa_services'
using_task_library 'telemetry_provider'
Syskit.conf.use_deployment FipaServices::MessageTransportTask => "#{Roby.app.robot_name}__fipa_services_message_transport_task"
Syskit.conf.use_deployment TelemetryProvider::Multiplexer => "#{Roby.app.robot_name}__telemetry_provider_multiplexer"
Syskit.conf.use_deployment TelemetryProvider::Demultiplexer => "#{Roby.app.robot_name}__telemetry_provider_demultiplexer"
Syskit.conf.use_deployment TelemetryProvider::FIPAPublisher => "#{Roby.app.robot_name}__telemetry_provider_fipa_publisher"
Syskit.conf.use_deployment TelemetryProvider::FIPASubscriber => "#{Roby.app.robot_name}__telemetry_provider_fipa_subscriber"
