#!/usr/bin/env ruby

require 'json'

outputs=JSON.load($stdin)

outputs['modules'][0]['outputs'].each { |k,v|
        puts "terraform_output_#{k}='#{v}'"
}
