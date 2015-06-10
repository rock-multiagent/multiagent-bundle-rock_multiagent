using_task_library 'fipa_services'
Syskit.conf.use_deployment FipaServices::MessageTransportTask => "message_transport_task__#{Roby.app.robot_name}"
