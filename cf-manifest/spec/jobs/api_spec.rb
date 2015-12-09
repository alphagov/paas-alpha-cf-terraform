
RSpec.describe "api jobs" do
  API_JOBS = %w(
    api_z1
    api_z2
  )

  let(:jobs) { manifest_with_defaults.fetch("jobs") }

  describe "common job properties" do
    API_JOBS.each do |job_name|
      context "job #{job_name}" do
        subject(:job) { jobs.find {|j| j["name"] == job_name } }

        describe "route registrar" do
          let(:routes) { job.fetch("properties").fetch("route_registrar").fetch("routes") }

          it "registers the correct uris" do
            expect(routes.length).to eq(1)
            expect(routes.first.fetch('uris')).to match_array([
              "api.#{terraform_fixture(:cf_root_domain)}",
            ])
          end
        end
      end
    end
  end
end
