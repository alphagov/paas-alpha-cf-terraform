#!/usr/bin/ruby
require 'yaml'
require 'pp'


files=ARGV
temp_yml = {}
#common = {}
#temp_yml['properties'] = {}

ARGV.each do |file|
  jobspec = YAML.load_file(file)
  job = jobspec['name']
  temp_yml["#{job}.properties"] = jobspec['properties']
#  jobspec['properties'].each do |k,v|
#    common[k] ||= []
#    common[k] << [job,v]
#  end
end

#common.select {|k,v| v.size > 1 }.each do |k,v|
#  temp_yml['properties'][k] = v[0][1]
#  v.each do |job,values|
#    default = v[0][1].dup
#    default['description'] = "don't care"
#    current = values
#    current['description'] = "don't care"
#    if current != default then
#      puts "Job #{job} has different values for property #{k}:"
#      puts "  #{values}"
#    end
#  end
#end

File.open('result.yml', 'w') {|f| f.write temp_yml.to_yaml } 

#pp common
#puts "----------------------"
#pp temp_yml

# For all files in input do
  # read file and extract properties hash into ['name'].'properties', building one big yaml which has each job's properties only

  # at the same time we want to be checking if any job properties repeat, create a hash called say 'common'
  # add all jobs properties into 'common'. Add job name into per-property list of all jobs having this property. Initialize properties with empty value.
    # Check the if the job's value (if it defines deafult, else the value is empty) is different than current value
      # if there was no default value then set the property to that job's default value
      # if there is a different value, log the discrepancy, note that jobs for this property have different values
 
# Go through all properties in 'common'
  # If any property has more than 1 job, add it to 'properties' (these are global properties)
  # If there are any discrepancies in values of the jobs, list all jobs and values of the property they set. Group by the property value (st. like sort | uniq -c)

# Output the resulting yml without 'common' hash. This file will be used by further tests.

#
#require 'yaml';
#
#uaa = YAML.load_file('jobs/uaa/spec')
#puts uaa['name']
#
#uaa['properties'].each do |name, details|
# if details.has_key?('default')
#   puts "#{name}: #{details['default']}"
# end
#end
#
#exit 0
