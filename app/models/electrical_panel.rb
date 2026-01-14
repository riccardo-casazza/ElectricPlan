class ElectricalPanel < ApplicationRecord
  include ComplianceAware

  belongs_to :room
  belongs_to :input_cable, class_name: "Cable", optional: true
  has_many :residual_current_devices, dependent: :destroy

  # Automatically generate name from Floor and Room initials before validation
  before_validation :generate_name, on: :create

  private

  def generate_name
    if room && room.floor
      floor_initial = room.floor.name[0].upcase
      room_initial = room.name[0].upcase
      self.name = "#{floor_initial}#{room_initial}"
    end
  end
end
