
RSpec.describe "base properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }

  it "sets the domain from the terraform outputs" do
    expect(properties["domain"]).to eq("unit-test.cf.paas.example.com")
  end
end
