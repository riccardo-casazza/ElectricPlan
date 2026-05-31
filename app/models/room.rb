class Room < ApplicationRecord
  include ComplianceAware

  belongs_to :floor
  has_many :electrical_panels, dependent: :destroy
  has_many :items, dependent: :destroy

  # Room types for NF C 15-100 socket requirements
  ROOM_TYPES = %w[living_room bedroom kitchen bathroom other].freeze

  validates :room_type, inclusion: { in: ROOM_TYPES }, allow_blank: true
end
