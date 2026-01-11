class Rule < ApplicationRecord
  has_many :rule_violations, dependent: :destroy

  validates :description, presence: true
  validates :applies_to, presence: true
  validates :rule, presence: true

  # Get the latest verification status
  def verification_status
    # Reload to get fresh data
    rule_violations.reload if rule_violations.loaded?

    return :not_verified if rule_violations.empty?

    unresolved = rule_violations.where(resolved: false)
    return :pass if unresolved.empty?
    :fail
  end

  def status_color
    case verification_status
    when :pass then "green"
    when :fail then "red"
    else "gray"
    end
  end

  def status_symbol
    case verification_status
    when :pass then "✓"
    when :fail then "✗"
    else "?"
    end
  end
end
