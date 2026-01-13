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

  def last_verification_time
    rule_violations.maximum(:created_at)
  end

  def last_verification_summary
    return "Not verified" unless last_verification_time

    time_ago = Time.current - last_verification_time
    time_text = if time_ago < 60
      "#{time_ago.to_i}s ago"
    elsif time_ago < 3600
      "#{(time_ago / 60).to_i}m ago"
    elsif time_ago < 86400
      "#{(time_ago / 3600).to_i}h ago"
    else
      "#{(time_ago / 86400).to_i}d ago"
    end

    "Verified #{time_text}"
  end
end
