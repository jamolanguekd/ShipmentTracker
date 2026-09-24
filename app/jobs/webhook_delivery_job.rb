require "net/http"
require "openssl"

class WebhookDeliveryJob < ApplicationJob
  BACKOFF_SCHEDULE = [30, 120, 600, 3600].freeze
  MAX_ATTEMPTS = 5

  def perform(delivery_id)
    delivery = WebhookDelivery.find(delivery_id)
    endpoint = delivery.webhook_endpoint
    body = delivery.payload.to_json

    signature = OpenSSL::HMAC.hexdigest("SHA256", endpoint.secret, body)

    uri = URI.parse(endpoint.url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 10
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["X-Webhook-Signature"] = signature
    request.body = body

    response = http.request(request)
    delivery.attempts += 1

    if response.code.to_i.between?(200, 299)
      delivery.update!(
        status: :success,
        response_code: response.code.to_i,
        response_body: response.body,
        delivered_at: Time.current
      )
    else
      handle_failure(delivery, response.code.to_i, response.body)
    end
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    delivery = WebhookDelivery.find(delivery_id)
    delivery.attempts += 1
    handle_failure(delivery, nil, e.message)
  end

  private

  def handle_failure(delivery, response_code, response_body)
    if delivery.attempts >= MAX_ATTEMPTS
      delivery.update!(
        status: :failed,
        response_code: response_code,
        response_body: response_body
      )
    else
      delay = BACKOFF_SCHEDULE[delivery.attempts - 1] || BACKOFF_SCHEDULE.last
      delivery.update!(
        response_code: response_code,
        response_body: response_body,
        next_retry_at: Time.current + delay
      )
      self.class.set(wait: delay.seconds).perform_later(delivery.id)
    end
  end
end
