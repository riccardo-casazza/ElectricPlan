class Dwelling < ApplicationRecord
  has_many :electrical_panels, dependent: :destroy

  validates :name, presence: true
end
