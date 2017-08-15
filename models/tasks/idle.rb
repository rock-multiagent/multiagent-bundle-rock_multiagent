require 'roby/tasks/thread'

module RockMultiagent
    module Tasks
        # Simple Idle task, which just runs for a given amount of time
        class Idle < Roby::Tasks::Thread
            attr_reader :start_time
            attr_reader :last_info_message

            argument :duration, :default => 1

            def initialize(arguments = Hash.new)
               super(arguments)
               @start_time = Time.now
               @last_info_message = nil
            end

            poll do 
                if Time.now - start_time > arguments[:duration]
                    Robot.info "Idle reached it's maximum duration of #{arguments[:duration]} s"
                    emit :success
                elsif !@last_info_message || (Time.now - @last_info_message) > 5
                    Robot.info "Elapsed time: #{Time.now - start_time} (timeout after: #{arguments[:duration]} seconds)"
                    @last_info_message = Time.now
                end
            end
        end
    end
end
