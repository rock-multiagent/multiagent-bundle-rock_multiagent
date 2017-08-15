module RockMultiagent
    module Tasks
        # Task in order to test calling the supervision through the planning interface.
        #
        # Also serves as a simple illustration on how to link Roby::Task with Composition using event forwarding (alternatively signalling can be applied as well, see comments in composition 'Probe'
        #
        class Probe < Roby::Task
            attr_reader :emitted_probing

            argument :first_arg, :default => ""
            argument :second_arg, :default => ""

            event :probing

            def initialize(arguments = Hash.new)
                super(arguments)
                @emitted_probing = false
            end

            poll do
                if !@emitted_probing
                    Robot.info "#{self} has been called with the following arguments: "
                    arguments.each do |key,value|
                        Robot.info "arg: #{key} value: #{value}"
                    end

                    emit :probing, first_arg, second_arg
                    @emitted_probing = true
                end
            end
        end
    end # Tasks
end # RockMultiagent
