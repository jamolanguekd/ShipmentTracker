class Shipment < ApplicationRecord
  # Status values are append-only; do not reorder existing entries
  enum status: { pending: 0, in_transit: 1, out_for_delivery: 2, delivered: 3, failed: 4 }

  has_many :tracking_events, dependent: :destroy

  validates :reference_number, presence: true, uniqueness: true
  validates :origin, presence: true
  validates :destination, presence: true
end
