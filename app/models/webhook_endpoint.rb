class WebhookEndpoint < ApplicationRecord
  ALLOWED_STATUSES = Shipment.statuses.keys.freeze

  belongs_to :shipment, optional: true
  has_many :webhook_deliveries, dependent: :destroy

  validates :url, presence: true
  validates :secret, presence: true
  validate :validate_status_filters

  scope :active, -> { where(active: true) }

  private

  def validate_status_filters
    return if status_filters.blank?

    invalid = status_filters - ALLOWED_STATUSES
    if invalid.any?
      errors.add(:status_filters, "contains invalid values: #{invalid.join(', ')}")
    end
  end
end
