class Item < ApplicationRecord
  include ComplianceAware

  belongs_to :breaker
  belongs_to :room
  belongs_to :item_type
  belongs_to :input_cable, class_name: "Cable", optional: true

  # Item types that require power specification
  POWER_REQUIRED_TYPES = %w[convector water\ heater a/c].freeze

  validates :power_watts, presence: true, numericality: { greater_than: 0 }, if: :requires_power?

  def requires_power?
    return false unless item_type
    POWER_REQUIRED_TYPES.include?(item_type.name.downcase)
  end
end
