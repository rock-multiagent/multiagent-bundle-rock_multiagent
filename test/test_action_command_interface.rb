require_relative '../scripts/controllers/action_command_interface'
require 'orocos'
Orocos.initialize

mts_task = Orocos.name_service.get_provides 'fipa_services::MessageTransportTask'

interface = RockMultiagent::ActionCommandInterface.new(nil, "commander", mts_task)
letter = interface.request_action("sherpa_tt","dummy_move_to",{:x => 0, :y => 0}) do |initial_request, response, status|
    puts "Update received: #{status}, from: #{response.getACLMessage.getSender.getName}"
end

while true
    interface.trigger
    status = interface.action_request_status?(letter)
    if status.include?("finalized")
        break
    end
    sleep 0.1
end
