class ResidualCurrentDeviceType < ApplicationRecord
  has_many :residual_current_devices, dependent: :restrict_with_error
end
