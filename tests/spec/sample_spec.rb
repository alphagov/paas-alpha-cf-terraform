require 'yaml'

RSpec.describe "some sample tests" do

  let(:manifest) {
    YAML.load_file(File.expand_path("../../../cf-manifest.yml", __FILE__))
  }

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
