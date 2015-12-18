#!/usr/bin/env ruby

require 'yaml'

filename = ARGV[0]
path = ARGV[1]

def get(hash, path_array)
	unless path_array.empty?
		get(hash[path_array[0]], path_array[1..-1])
	else
		hash
	end
end

secrets_hash = YAML.load_file(filename)
path_array = path.split('/')
puts get(secrets_hash, path_array)
