require 'roby/task'

module RockMultiagent
    module Tasks
        # Simple Idle task, which just runs for a given amount of time
        class Idle < Roby::Task
            attr_reader :start_time

            argument :duration, :default => 1

            def initialize(arguments = Hash.new)
                begin
                super(arguments)
                @start_time = Time.now
                rescue Exception => e
                    puts "Exception: #{e}"
                end
            end

            poll do 
                begin
                if Time.now - start_time > arguments[:duration]
                    Robot.info "Idle reached it's maximum duration of #{arguments[:duration]} s"
                    emit :success
                end
                rescue Exception => e
                    puts "Exception: #{e}"
                end
            end
        end
    end
end
