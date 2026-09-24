require "rails_helper"
require "net/http"

RSpec.describe WebhookDeliveryJob, type: :job do
  let(:endpoint) { create(:webhook_endpoint, url: "https://example.com/hook", secret: "test_secret") }
  let(:tracking_event) { create(:tracking_event) }
  let(:delivery) do
    create(:webhook_delivery,
      webhook_endpoint: endpoint,
      tracking_event: tracking_event,
      payload: { event: "tracking_event.created", data: { id: 1 } }
    )
  end

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe "#perform" do
    it "marks delivery as success on 2xx response" do
      stub_request_with(Net::HTTPOK, "200", "OK")
      described_class.new.perform(delivery.id)
      delivery.reload
      expect(delivery.success?).to be true
      expect(delivery.response_code).to eq(200)
      expect(delivery.delivered_at).to be_present
      expect(delivery.attempts).to eq(1)
    end

    it "sends correct HMAC signature" do
      captured_body = nil
      actual_sig = nil

      allow(Net::HTTP).to receive(:new).and_return(
        instance_double(Net::HTTP,
          "use_ssl=" => nil,
          "open_timeout=" => nil,
          "read_timeout=" => nil
        ).tap do |http|
          allow(http).to receive(:request) do |req|
            actual_sig = req["X-Webhook-Signature"]
            captured_body = req.body
            mock_response(Net::HTTPOK, "200", "OK")
          end
        end
      )

      described_class.new.perform(delivery.id)
      expected_sig = OpenSSL::HMAC.hexdigest("SHA256", "test_secret", captured_body)
      expect(actual_sig).to eq(expected_sig)
    end

    it "retries on non-2xx response with exponential backoff" do
      stub_request_with(Net::HTTPInternalServerError, "500", "Error")
      described_class.new.perform(delivery.id)
      delivery.reload
      expect(delivery.pending?).to be true
      expect(delivery.attempts).to eq(1)
      expect(delivery.response_code).to eq(500)
      expect(delivery.next_retry_at).to be_present
      expect(described_class).to have_been_enqueued.exactly(:once)
    end

    it "marks delivery as failed after max attempts" do
      delivery.update!(attempts: 4)
      stub_request_with(Net::HTTPInternalServerError, "500", "Error")
      described_class.new.perform(delivery.id)
      delivery.reload
      expect(delivery.failed?).to be true
      expect(delivery.attempts).to eq(5)
    end

    it "does not re-enqueue after max attempts" do
      delivery.update!(attempts: 4)
      stub_request_with(Net::HTTPInternalServerError, "500", "Error")
      described_class.new.perform(delivery.id)
      expect(described_class).not_to have_been_enqueued
    end

    it "handles timeout errors" do
      allow(Net::HTTP).to receive(:new).and_return(
        instance_double(Net::HTTP,
          "use_ssl=" => nil,
          "open_timeout=" => nil,
          "read_timeout=" => nil
        ).tap do |http|
          allow(http).to receive(:request).and_raise(Net::ReadTimeout)
        end
      )

      described_class.new.perform(delivery.id)
      delivery.reload
      expect(delivery.pending?).to be true
      expect(delivery.attempts).to eq(1)
      expect(delivery.response_code).to be_nil
    end

    it "truncates long response bodies" do
      long_body = "x" * 2000
      stub_request_with(Net::HTTPOK, "200", long_body)
      described_class.new.perform(delivery.id)
      delivery.reload
      expect(delivery.response_body.bytesize).to eq(1024)
    end
  end

  private

  def stub_request_with(klass, code, body)
    allow(Net::HTTP).to receive(:new).and_return(
      instance_double(Net::HTTP,
        "use_ssl=" => nil,
        "open_timeout=" => nil,
        "read_timeout=" => nil,
        request: mock_response(klass, code, body)
      )
    )
  end

  def mock_response(klass, code, body)
    instance_double(klass, code: code, body: body)
  end
end
