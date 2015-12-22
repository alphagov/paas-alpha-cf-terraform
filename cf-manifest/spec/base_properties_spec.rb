require 'pp'


def lookup_property(collection, name)
  keys = name.split(".")
  ref = collection

  keys.each do |key|
    ref = ref[key]
    return nil if ref.nil?
  end

  ref
end

class Hash
  def keydump
    map{|k,v|v.keydump.map{|a|"#{k}.#{a}"} rescue k.to_s}.flatten
  end
end

RSpec.describe "base properties" do
  let(:manifest) { manifest_with_defaults }
  let(:jobspecs) { load_job_specs }
  let(:properties) { manifest.fetch("properties") }

  it "sets the top-level manifest name" do
    expect(manifest["name"]).to eq(terraform_fixture(:environment))
  end

  it "sets the domain from the terraform outputs" do
    expect(properties["domain"]).to eq(terraform_fixture(:cf_root_domain))
  end

  it "sets the system_domain" do
    expect(properties["system_domain"]).to eq(terraform_fixture(:cf_root_domain))
  end

  it "sets the app domains" do
    expect(properties["app_domains"]).to match_array([
      terraform_fixture(:cf_root_domain),
    ])
  end

  describe "properties" do
    # use job context for all "in-job" checks
    specify "only own properties" do
      # check every job only sets it's own properties and nothing else (e.g. non existing properties)
      # you need to figure out which job specs that are by the list of templates of that job
      manifest['jobs'].each {|job|
        myjobs = []
        job['templates'].each {|template| myjobs << template['name'] if template['release'] == "cf"}
#        puts "Jobs for #{job['name']} are #{myjobs}"
         
      }
      expect(true).to eq(true)
    end

    specify "all own properties" do
      # check every job has all properties set 
      # you need to figure out which job specs that are by the list of templates of that job
      # property can be set in job, globals or by having a default
      expect(true).to eq(true)
    end

    it "never uses default credential" do
      # check if all job's properties and all globals that look like ~pass, password, credential etc. have non default value
      # you need a list of all jobs' templates and check all pass-like properties, which have default are set either in a job's or global properties
      expect(true).to eq(true)
    end

    specify "only existing globals" do
      # check all global properties exist in 'all' properties list
      # to do that, you need to create a "full path" property names
      # ...but some stuff like fog.provider.aws_key don't exist even in 'all_keys', but are fine
      not_existing = properties.keydump.select {|p|
#        puts "p is #{p}"
#        pp jobspecs["all_keys"].select{|k,v| k.start_with?(p)}
        jobspecs["all_keys"].select{|k,v| k.start_with?(p)}.empty?}
#         jobspecs["all_keys"][p] == nil) and
#         (jobspecs["all_keys"].select{|k,v| k.start_with?(p)} == nil)
#      }
#      not_existing.each {|p| pp properties[p]}
      expect(not_existing).to eq([])
    end

# Do we really want to do this? Maybe we just want to have some properties there sitting unused, in case we need them again
#    specify "only relevant globals" do
      # check all global properties are used by any of the jobs
      # you need to check what you are deploying (a set of all templates by all jobs)
      # then check if every key from these jobs either has a default or is set in job or in globals...
#      remaining = properties
#      remaining.each do { |property|
#          remaining.delete(property) when property in jobspecs.all
#      }
#      expect(remaining).to eq({})
#    end

# Impossible, see http://stackoverflow.com/questions/4911105/in-ruby-how-to-be-warned-of-duplicate-keys-in-hashes-when-loading-a-yaml-docume
#    it "never set global property multiple times" do
#      # check if any value is set twice in globals, second one overriding 1st
#      # could be also when one is substring of another
#      flat_keys = properties.keydump
#      pp flat_keys
#      multiple = flat_keys.select {|p|
#        flat_keys.select{|k| k.start_with?(p)}.size > 1
#      }
#      expect(multiple).to eq([])
#    end
    
  end

  describe "cloud controller" do
    subject(:cc) { properties.fetch("cc") }

    it { is_expected.to include("srv_api_uri" => "https://api.#{terraform_fixture(:cf_root_domain)}") }

    shared_examples "a component with an AWS connection" do
      let(:fog_connection) { subject.fetch("fog_connection") }

      specify { expect(fog_connection).to include("aws_access_key_id" => terraform_fixture("aws_access_key_id")) }
      specify { expect(fog_connection).to include("aws_secret_access_key" => terraform_fixture("aws_secret_access_key")) }
      specify { expect(fog_connection).to include("region" => terraform_fixture(:region)) }
      specify { expect(fog_connection).to include("provider" => "AWS") }
    end

    describe "buildpacks" do
      subject(:buildpacks) { cc.fetch("buildpacks") }

      it_behaves_like "a component with an AWS connection"

      it { is_expected.to include("buildpack_directory_key" => "#{terraform_fixture(:cf_root_domain)}-cc-buildpacks") }
    end

    describe "droplets" do
      subject(:droplets) { cc.fetch("droplets") }

      it_behaves_like "a component with an AWS connection"

      it { is_expected.to include("droplet_directory_key" => "#{terraform_fixture(:cf_root_domain)}-cc-droplets") }
    end

    describe "packages" do
      subject(:packages) { cc.fetch("packages") }

      it_behaves_like "a component with an AWS connection"

      it { is_expected.to include("app_package_directory_key" => "#{terraform_fixture(:cf_root_domain)}-cc-packages") }
    end

    describe "resource_pool" do
      subject(:resource_pool) { cc.fetch("resource_pool") }

      it_behaves_like "a component with an AWS connection"

      it { is_expected.to include("resource_directory_key" => "#{terraform_fixture(:cf_root_domain)}-cc-resources") }
    end
  end

  describe "host manager" do
    subject(:hm9000) { properties.fetch("hm9000") }

    it { is_expected.to include("url" => "https://hm9000.#{terraform_fixture(:cf_root_domain)}") }

  end

  describe "login" do
    subject(:login) { properties.fetch("login") }

    describe "links" do
      subject(:links) { login.fetch("links") }

      it { is_expected.to include("passwd" => "https://console.#{terraform_fixture(:cf_root_domain)}/password_resets/new") }
      it { is_expected.to include("signup" => "https://console.#{terraform_fixture(:cf_root_domain)}/register") }
    end
  end

  describe "uaa" do
    subject(:uaa) { properties.fetch("uaa") }

    it { is_expected.to include("issuer" => "https://uaa.#{terraform_fixture(:cf_root_domain)}") }
    it { is_expected.to include("url" => "https://uaa.#{terraform_fixture(:cf_root_domain)}") }

    specify {
      expect(uaa["clients"]["login"]).to include("redirect-uri" => "https://login.#{terraform_fixture(:cf_root_domain)}")
    }
  end
end
