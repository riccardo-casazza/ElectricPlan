class RuleViolation < ApplicationRecord
  belongs_to :rule

  validates :resource_type, presence: true
  validates :resource_id, presence: true
  validates :message, presence: true

  def resource
    resource_type.constantize.find_by(id: resource_id)
  end
end
