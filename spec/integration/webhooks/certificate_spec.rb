require "pact_broker/domain/webhook_request"
require "faraday"
# certificates and key generated by script/generate-certificates-for-webooks-certificate-spec.rb

describe "executing a webhook to a server with a self signed certificate" do
  def wait_for_server_to_start
    Faraday.new(url: "https://localhost:4444", ssl: {verify: false}) do |builder|
      builder.request :retry, max: 20, interval: 0.5, exceptions: [StandardError]
      builder.adapter :net_http
    end.get
  end

  before(:all) do
    @pipe = IO.popen("bundle exec ruby spec/support/ssl_webhook_server.rb")
    wait_for_server_to_start
  end

  let(:webhook_request) do
    PactBroker::Domain::WebhookRequest.new(
      method: "get",
      url: "https://localhost:4444/")
  end

  subject { webhook_request.execute }

  context "without the correct cacert" do
    it "fails" do
      expect { subject }.to raise_error(OpenSSL::SSL::SSLError)
    end
  end

  context "with the correct cacert in the database" do
    let!(:certificate) do
      td.create_certificate(path: "spec/fixtures/certificates/cacert.pem")
    end

    it "succeeds" do
      puts subject.body unless subject.code == "200"
      expect(subject.code).to eq "200"
    end
  end

  context "with the correct embedded cacert in the configuration" do
    include Anyway::Testing::Helpers

    around do |ex|
      with_env("PACT_BROKER_CONF" => PactBroker.project_root.join("spec/support/config_webhook_certificates.yml").to_s, &ex)
    end

    it "succeeds" do
      puts subject.body unless subject.code == "200"
      expect(subject.code).to eq "200"
    end
  end

  after(:all) do
    Process.kill "KILL", @pipe.pid
  end
end
