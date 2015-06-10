require 'rock_multiagent/models/actions/multiagent_communication'

# The main planner. A planner of this model is automatically added in the
# Interface planner list.
class Main < Roby::Actions::Interface
    use_library Rock::Multiagent::Actions::Communication
end

