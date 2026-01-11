class Room < ApplicationRecord
  belongs_to :floor
  has_many :electrical_panels, dependent: :destroy
  has_many :items, dependent: :destroy
end
