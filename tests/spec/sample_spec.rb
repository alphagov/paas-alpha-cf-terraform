require 'yaml'
require 'cli'

RSpec.describe "some sample tests" do
  let(:manifest_file) { File.expand_path("../../../cf-manifest.yml", __FILE__) }
  let(:manifest) { YAML.load_file(manifest_file) }

  let(:mock_bosh_releases) {
    [
      { "name"=>"cf", "release_versions"=>[{"version"=>"215"}] },
      { "name"=>"cf-redis", "release_versions"=>[{"version"=>"420"}] },
      { "name"=>"collectd", "release_versions"=>[{"version"=>"ec9de5dc63715237688c3b27154c86a0c22b3aef"}] },
      { "name"=>"elasticsearch", "release_versions"=>[{"version"=>"0.1.0"}] },
      { "name"=>"grafana", "release_versions"=>[{"version"=>"44564533c9d4d656bdcd5633b808f0bf6fb177ae"}] },
      { "name"=>"graphite", "release_versions"=>[{"version"=>"0d79bf5aa5f2cf29195bff725d7dee55dea1aedc"}] },
      { "name"=>"logsearch", "release_versions"=>[{"version"=>"23.0.0"}] },
      { "name"=>"logsearch-for-cloudfoundry", "release_versions"=>[{"version"=>"7"}] },
      { "name"=>"nginx", "release_versions"=>[{"version"=>"2"}] },
    ]
  }
  let(:mock_bosh_stemcells) {
    [{"name"=>"bosh-aws-xen-hvm-ubuntu-trusty-go_agent", "version"=>"3074"}]
  }

  it "should be valid" do
    mock_director = double("Director", :uuid => 'BOSH_UUID')
    allow(mock_director).to receive(:list_releases).and_return(mock_bosh_releases)
    allow(mock_director).to receive(:list_stemcells).and_return(mock_bosh_stemcells)

    m = Bosh::Cli::Manifest.new(manifest_file, mock_director)
    m.load

    expect { m.validate }.not_to raise_error
  end

  it "should contain 5 jobs" do
    expect(manifest["jobs"].size).to eq(33)
  end

  describe "the runner_z1 job" do
    let(:runner_job) { manifest["jobs"].find {|j| j["name"] == "runner_z1" } }


    it "should have 1 instance" do
      expect(runner_job["instances"]).to eq(1)
    end

    it "should use the correct templates" do
      template_names = runner_job["templates"].map {|t| t["name"] }

      expect(template_names).to match_array(%w[
        dea_next
        dea_logging_agent
        metron_agent
        collectd
      ])
    end
  end
end
