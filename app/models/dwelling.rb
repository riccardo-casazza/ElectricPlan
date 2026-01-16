class Dwelling < ApplicationRecord
  has_many :electrical_panels, dependent: :destroy

  validates :name, presence: true

  # Get dwelling-level compliance violations
  def compliance_violations
    @compliance_violations ||= engine.check_dwelling(self)
  end

  # Get all violations (dwelling-level + all electrical panels)
  def all_violations
    violations = compliance_violations.dup
    electrical_panels.each do |panel|
      violations.concat(panel.all_violations)
    end
    violations
  end

  # Check if this dwelling has any error-level violations
  def has_compliance_errors?
    all_violations.any?(&:error?)
  end

  # Check if this dwelling is fully compliant
  def compliant?
    all_violations.empty?
  end

  # Clear memoized violations (useful after updates)
  def clear_compliance_cache
    @compliance_violations = nil
  end

  private

  def engine
    @engine ||= ComplianceEngine.new
  end
end
