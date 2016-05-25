require 'rock_multiagent/models/actions/multiagent_communication'
require 'rock_multiagent/models/profiles'

# The main planner. A planner of this model is automatically added in the
# Interface planner list.
module RockMultiagent
    module Actions
        class Common < Roby::Actions::Interface
            use_profile RockMultiagent::Profile
            use_library RockMultiagent::Actions::Communication
        end
    end
end

