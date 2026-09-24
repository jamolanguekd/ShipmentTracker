class WebhookDelivery < ApplicationRecord
  enum status: { pending: 0, success: 1, failed: 2 }

  belongs_to :webhook_endpoint
  belongs_to :tracking_event

  before_validation :truncate_response_body

  private

  def truncate_response_body
    self.response_body = response_body&.byteslice(0, 1024)
  end
end
