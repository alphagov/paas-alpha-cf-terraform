#!/usr/bin/env ruby

require 'cli'

bosh_cli = Bosh::Cli::Command::Base.new.director
deployments = bosh_cli.list_deployments.map { |d| d["name"] }

if deployments.empty?
    puts "No deployments"
    exit
end

puts "Deployments: #{deployments.join(', ')}"

if ARGV[0] == "-y"
    delete = true
else
    print "Delete all deployments? [yn] "
    delete = true if gets.strip[0].downcase == 'y'
end

if delete
    deployments.each { |d|
        puts "Delete deployment #{d}"
        bosh_cli.delete_deployment(d)
    }
end
