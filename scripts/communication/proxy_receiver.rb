#! /usr/bin/env ruby

require 'rock/bundle'
require 'optparse'
require 'securerandom'

uuid=SecureRandom.uuid.gsub("-","")

o_name = "#{uuid}-proxy-client"
opt_parser = OptionParser.new do |opt|
    opt.banner = "Usage: ruby proxy_sender.rb [options]"

    opt.on '--name [name]', String, "name" do |n|
        o_name = n
    end
end
opt_parser.parse!

puts "Running proxy client: #{o_name}"

include Orocos
Orocos::CORBA.max_message_size = 120000000
Bundles.initialize

Bundles.run "fipa_services::MessageTransportTask" => "proxy_receiver_message_transport",
    "telemetry_provider::Demultiplexer" => "proxy_demultiplexer",
    "telemetry_provider::FIPASubscriber" => "proxy_fipa_subscriber" do

    mts = Orocos.get 'proxy_receiver_message_transport'
    mts.apply_conf_file("fipa_services::MessageTransportTask.yml",["default","receiver"], true)
    mts.configure
    mts.start
    mts.addReceiver(o_name, true)

    subscriber = Orocos.get 'proxy_fipa_subscriber'
    subscriber.configure
    subscriber.start

    demultiplexer = Orocos.get 'proxy_demultiplexer'
    demultiplexer.configure
    demultiplexer.start

    mts.port(o_name).connect_to subscriber.fipa_message, :type => :buffer, :size => 25
    subscriber.telemetry_package.connect_to demultiplexer.telemetry_package, :type => :buffer, :size => 25

    Orocos.watch(mts, demultiplexer, subscriber)
end
    
