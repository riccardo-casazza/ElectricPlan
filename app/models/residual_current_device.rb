class ResidualCurrentDevice < ApplicationRecord
  belongs_to :electrical_panel
  belongs_to :residual_current_device_type
  has_many :breakers, dependent: :destroy

  validates :row_number, numericality: { greater_than_or_equal_to: 1 }
  validates :position, numericality: { greater_than_or_equal_to: 1 }
  validates :output_max_current, numericality: { greater_than_or_equal_to: 1 }
  validate :row_number_must_be_sequential
  validate :position_must_be_sequential

  before_validation :generate_name

  private

  def generate_name
    if electrical_panel && row_number && position && output_max_current
      self.name = "#{electrical_panel.name}-#{row_number}#{position}-#{output_max_current}"
    end
  end

  def row_number_must_be_sequential
    return unless row_number && electrical_panel_id

    # Get all row numbers for this panel, excluding the current record if updating
    existing_rows = ResidualCurrentDevice.where(electrical_panel_id: electrical_panel_id)
                                         .where.not(id: id)
                                         .pluck(:row_number)
                                         .compact
                                         .sort

    return if existing_rows.empty? # First row is always valid

    max_existing_row = existing_rows.max || 0

    # New row must be either existing or max + 1
    unless existing_rows.include?(row_number) || row_number == max_existing_row + 1
      errors.add(:row_number, "must be sequential. Next available row is #{max_existing_row + 1}")
    end
  end

  def position_must_be_sequential
    return unless position && electrical_panel_id && row_number

    # Get all positions for this panel and row, excluding the current record if updating
    existing_positions = ResidualCurrentDevice.where(electrical_panel_id: electrical_panel_id, row_number: row_number)
                                              .where.not(id: id)
                                              .pluck(:position)
                                              .compact
                                              .sort

    return if existing_positions.empty? # First position in a row is always valid

    max_existing_position = existing_positions.max || 0

    # New position must be either existing or max + 1
    unless existing_positions.include?(position) || position == max_existing_position + 1
      errors.add(:position, "must be sequential for this row. Next available position is #{max_existing_position + 1}")
    end
  end
end
