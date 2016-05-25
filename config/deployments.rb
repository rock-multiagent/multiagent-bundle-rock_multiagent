using_task_library 'fipa_services'
Syskit.conf.use_deployment FipaServices::MessageTransportTask => "#{Roby.app.robot_name}__message_transport_task"
