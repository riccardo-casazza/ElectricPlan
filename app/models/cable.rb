class Cable < ApplicationRecord
  has_many :electrical_panels, foreign_key: :input_cable_id, dependent: :restrict_with_error
  has_many :items, foreign_key: :input_cable_id, dependent: :restrict_with_error
end
