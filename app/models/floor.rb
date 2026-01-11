class Floor < ApplicationRecord
  has_many :rooms, dependent: :destroy
end
