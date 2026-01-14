class Item < ApplicationRecord
  include ComplianceAware

  belongs_to :breaker
  belongs_to :room
  belongs_to :item_type
  belongs_to :input_cable, class_name: "Cable", optional: true
end
