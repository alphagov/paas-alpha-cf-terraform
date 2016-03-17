# encoding: UTF-8
# # Based on http://stackoverflow.com/a/33524573/395686
# and https://jsosic.wordpress.com/tag/logstash-rspec/
# and https://github.com/cloudfoundry-community/logsearch-for-cloudfoundry

require 'filter_test_helpers'

require "yaml"

cc_bulk_app_state_response = '<14>2016-03-17T11:39:30.037252+00:00 10.0.10.41 vcap.cloud_controller_ng [job=api_z1 index=0] {"timestamp":1458214770.0371015,"message":"received + response","log_level":"info","source":"cc.healthmanager.client","data":{"request_guid":"f9530b4f-2b2e-4ee6-7191-aace60034cbc::d98cffb3-5295-4ad4-bb2b-37fce9c41dc8","message":[{"droplet":"8ff21266-4444-427e-8c42-db8b630479b2","version":"40f131cd-5548-4b0f-865e-486a88796428"}],"responses":{"8ff21266-4444-427e-8c42-db8b630479b2":{"droplet":"8ff21266-4444-427e-8c42-db8b630479b2","version":"40f131cd-5548-4b0f-865e-486a88796428","desired":{"id":"","version":"","instances":0,"state":"","package_state":""},"instance_heartbeats":[{"droplet":"8ff21266-4444-427e-8c42-db8b630479b2","version":"40f131cd-5548-4b0f-865e-486a88796428","instance":"51a12e90b03d4b0eaddc0abaa326dd69","index":0,"state":"RUNNING","state_timestamp":1458214758.0,"dea_guid":"0-1d886652c9674691b81071dbabcdd153"},{"droplet":"8ff21266-4444-427e-8c42-db8b630479b2","version":"40f131cd-5548-4b0f-865e-486a88796428","instance":"f46f703b54e24652bfee5fa790ec0f31","index":1,"state":"RUNNING","state_timestamp":1458214768.4,"dea_guid":"0-05c2393aeedf48e693ba12281bb0c11d"}],"crash_counts":[]}}},"thread_id":70010513410440,"fiber_id":70010513636780,"process_id":15149,"file":"/var/vcap/packages/cloud_controller_ng/cloud_controller_ng/lib/cloud_controller/dea/hm9000/client.rb","lineno":103,"method":"make_request"}'

describe "Remove data.responses" do

  before(:all) do
    load_filters <<-CONFIG
      filter {
        #{YAML.load_file(File.join(File.dirname(__FILE__), '../../manifests/templates/logsearch/logsearch-filters.yml'))["properties"]["logstash_parser"]["filters"]}
      }
    CONFIG
  end

  when_parsing_log(
    "@type" => "syslog",
    "@message" => cc_bulk_app_state_response
  ) do
    it "blabla" do
      expect(subject["@message"]).to_not be_nil
      expect(subject["data"]).to_not be_nil

    end
  end



end
