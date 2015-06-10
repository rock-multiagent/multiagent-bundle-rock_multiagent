require 'rock_multiagent/models/compositions/message_transport'

class FipaServices::MessageTransportTask
    def configure
        super
        orocos_task.local_receivers = [ "#{Roby.app.robot_name}" ]
    end
end
