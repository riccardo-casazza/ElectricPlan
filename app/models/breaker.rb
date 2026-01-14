class Breaker < ApplicationRecord
  include ComplianceAware

  belongs_to :residual_current_device
  has_many :items, dependent: :destroy

  validates :position, numericality: { greater_than_or_equal_to: 1 }
  validates :output_max_current, numericality: { greater_than_or_equal_to: 1 }
  validate :position_must_be_sequential

  before_validation :generate_name

  private

  def generate_name
    if residual_current_device && position && output_max_current
      self.name = "#{residual_current_device.name}-#{position}-#{output_max_current}"
    end
  end

  def position_must_be_sequential
    return unless position && residual_current_device_id

    # Skip validation if updating and position hasn't changed
    return if persisted? && position == position_was

    # Get all positions for this RCD, excluding the current record if updating
    existing_positions = Breaker.where(residual_current_device_id: residual_current_device_id)
                                 .where.not(id: id)
                                 .pluck(:position)
                                 .compact
                                 .sort

    return if existing_positions.empty? # First position is always valid

    max_existing_position = existing_positions.max || 0

    # New position must be either existing or max + 1
    unless existing_positions.include?(position) || position == max_existing_position + 1
      errors.add(:position, "must be sequential. Next available position is #{max_existing_position + 1}")
    end
  end
end
