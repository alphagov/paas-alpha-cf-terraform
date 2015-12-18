#!/usr/bin/ruby
require 'yaml'

results = {}
results['all_keys'] = {}
ARGV.each do |file|
  jobspec = YAML.load_file(file)
  results["#{jobspec['name']}.properties"] = jobspec['properties']
  jobspec['properties'].each {|k,v| results["all_keys"][k] = "exists"}
end

File.open('job_specs.yml', 'w') {|f| f.write results.to_yaml}

