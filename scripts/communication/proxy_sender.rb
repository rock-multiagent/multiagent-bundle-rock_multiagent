#! /usr/bin/env ruby
require 'rock/bundle'
require 'optparse'

o_receiver=".*-proxy-client"
o_sender=nil
o_config_file='proxy_config.yml'
o_buffer_size=25

opt_parser = OptionParser.new do |opt|
    opt.banner = "Usage: ruby proxy_sender.rb [options]"

    opt.on '--receiver <receiver>', String, "Name of the receiving agent (or a regex for mulitcasting)" do |r|
        o_receiver = r
    end
    opt.on '--sender <sender>', String, "Unique name of the sending agent" do |s|
        o_sender = s
    end
    opt.on '--config <file>', String, "Name of the configuration to load for the proxy" do |f|
        o_config_file
    end
    opt.on '--connection_buffer <buffer_size>', Int, "Size of the connection buffer" do |size|
        o_buffer_size=size
    end
end
opt_parser.parse!


include Orocos
Orocos::CORBA.max_message_size = 120000000
Bundles.initialize

module Proxy
    class TaskConfig
        attr_reader :task_name
        attr_reader :ports
        attr_reader :period

        def initialize(task_name, ports, period = 0)
            @task_name = task_name
            @ports = ports
            @period = period 
        end
    end

    # The following Proxy::Config allow to parse a configuration file
    # in order to setup a proxy base on fipa message transport
    #
    # The configuration file (yaml format) should look like the following, where
    # not specified ports will trigger the forwarding of all ports of a named
    # task
    #
    # ---
    # - task: mapper
    #   ports: 
    #     - envire_map
    #   period: 0.1
    # - task: camera_usb_deployment
    #   ports:
    #       # - frame
    #   period: 0.1
    class Config
        attr_reader :tasks

        # Per default load the proxy_config.yml
        def self.parse_proxy_config(file = nil)
            if !file
                file = File.join(File.expand_path(File.dirname(__FILE__)), 'proxy_config.yml')
            elsif !File.exist?(file)
                raise ArgumentError, "Proxy::Config: File #{file} cannot be found"
            end
            configuration = YAML.load_file(file)

            tasks = Hash.new
            configuration.each do |entry|
                if !entry.has_key?('task')
                    raise ArgumentError, "Proxy::Config: Entry '#{entry}' is missing the task name"
                end
                task = entry['task']

                ports = nil
                if !entry.has_key?('ports')
                    puts "Proxy::Config: Task '#{task}': no particular port selected, will use all ports"
                else
                    ports = entry['ports']
                end
               
                period = entry['period']
                task_config = TaskConfig.new(task, ports, period)
                if tasks.has_key?(task)
                    raise ArgumentError, "Proxy::Config: Duplicate entry for task '#{task}'}"
                end
                tasks[ entry['task'] ] = task_config
            end
            tasks
        end

        def self.activate_config(multiplexer, file = nil)
            tasks = parse_proxy_config(file)
            activate_tasks(tasks, multiplexer)
        end

        def self.activate_tasks(tasks, multiplexer)
            tasks.each do |name, config|
                begin
                    activate_config_for_running_task(config, multiplexer)
                rescue Exception => e
                    puts "Proxy::Config: Failed to activate task: '#{name}': #{e}"
                end
            end
        end

        # task, port_name, type
        def self.activate_config_for_running_task(task_config, multiplexer)
            task_name = task_config.task_name
            task = Orocos.get task_name

            if !task_config.ports
                task.each_output_port do |p|
                    enable_port(task, p.name, multiplexer)
                end
            else
                task_config.ports.each do |port_name|
                    enable_port(task, port_name, multiplexer)
                end
            end
        end

        def self.enable_port(task, port_name, multiplexer)
            port = task.port(port_name)
            port_type = port.type.name
            proxy_port_name = "#{task.name}__#{port_name}"

            if !multiplexer.createTelemetryInputPort(proxy_port_name, port_type)
                raise RuntimeError, "Proxy::Config: Failed to create telemetry input port: #{proxy_port_name}"
            end

            port.connect_to multiplexer.port(proxy_port_name), :type => :buffer, :size => o_buffer_size
        end
    end
end



Bundles.run "fipa_services::MessageTransportTask" => "proxy_message_transport",
    "telemetry_provider::Multiplexer" => "proxy_multiplexer",
    "telemetry_provider::FIPAPublisher" => "proxy_fipa_publisher" do

    mts = Orocos.get 'proxy_message_transport'
    mts.apply_conf_file("fipa_services::MessageTransportTask.yml", ["default"])
    mts.configure
    mts.start

    publisher = Orocos.get 'proxy_fipa_publisher'
    publisher.apply_conf_file("telemetry_provider::FIPAPublisher.yml", ["default"])
    if o_receiver
        publisher.receiver = o_receiver
    else
        puts "No receiver given: using value from config file: #{publisher.receiver}"
    end
    if o_sender
        publisher.sender = o_sender
    else
        puts "No sender given: using value from config file: #{publisher.sender}"
    end
    publisher.configure
    publisher.start


    multiplexer = Orocos.get 'proxy_multiplexer'
    multiplexer.configure
    multiplexer.start

    multiplexer.telemetry_package.connect_to publisher.telemetry_package, :type => :buffer, :size => o_buffer_size
    publisher.fipa_message.connect_to mts.letters, :type => :buffer, :size => o_buffer_size


    Proxy::Config::activate_config(multiplexer)

    Orocos.watch(mts, multiplexer, publisher)
end
    
