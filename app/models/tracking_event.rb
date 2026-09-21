class TrackingEvent < ApplicationRecord
  # Status values are append-only; do not reorder existing entries
  enum status: { pending: 0, in_transit: 1, out_for_delivery: 2, delivered: 3, failed: 4 }

  belongs_to :shipment

  validates :status, presence: true
  validates :occurred_at, presence: true
end
