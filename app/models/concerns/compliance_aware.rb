module ComplianceAware
  extend ActiveSupport::Concern

  # Get all compliance violations for this resource
  # Returns an array of ComplianceViolation objects
  # Uses memoization for performance (only checks once per request)
  def compliance_violations
    @compliance_violations ||= engine.check_resource(self)
  end

  # Get upstream violations (from parent resources)
  # For example, if a Breaker has violations, all its Items are affected
  def upstream_violations
    @upstream_violations ||= engine.check_upstream_violations(self)
  end

  # Get downstream violations (from child resources)
  # For example, if an RCD has violations in its Breakers
  def downstream_violations
    @downstream_violations ||= engine.check_downstream_violations(self)
  end

  # Get all violations (own + upstream + downstream)
  def all_violations
    compliance_violations + upstream_violations + downstream_violations
  end

  # Check if this resource has any error-level violations
  def has_compliance_errors?
    compliance_violations.any?(&:error?)
  end

  # Check if this resource has any warnings
  def has_compliance_warnings?
    compliance_violations.any?(&:warning?)
  end

  # Check if this resource is fully compliant
  def compliant?
    compliance_violations.empty?
  end

  # Get only error-level violations
  def compliance_errors
    compliance_violations.select(&:error?)
  end

  # Get only warning-level violations
  def compliance_warnings
    compliance_violations.select(&:warning?)
  end

  # Clear memoized violations (useful after updates)
  def clear_compliance_cache
    @compliance_violations = nil
    @upstream_violations = nil
    @downstream_violations = nil
  end

  private

  def engine
    @engine ||= ComplianceEngine.new
  end
end
