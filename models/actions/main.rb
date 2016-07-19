require 'rock_multiagent/models/actions'

module RockMultiagent
    module Actions
        class Main < Roby::Actions::Interface
            use_library RockMultiagent::Actions::Common
        end
    end
end
