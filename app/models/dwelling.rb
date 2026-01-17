class Dwelling < ApplicationRecord
  include Aq2Zone

  has_many :electrical_panels, dependent: :destroy

  validates :name, presence: true

  # Location helper methods using Carmen
  def country
    Carmen::Country.coded(country_code) if country_code.present?
  end

  def region
    return nil unless country && region_code.present?
    country.subregions.coded(region_code)
  end

  def department
    return nil unless region && department_code.present?
    region.subregions.coded(department_code)
  end

  def country_name
    country&.name
  end

  def region_name
    region&.name
  end

  def department_name
    department&.name
  end

  def full_location
    [ department_name, region_name, country_name ].compact.join(", ")
  end

  # Determine if surge protection is required per NF C 15-100
  # Returns true if any of these conditions are met:
  # 1. Has lightning protection (lightning rod or within 50m of protected building)
  # 2. Has overhead power line AND is in AQ2 zone
  # 3. Has safety-critical persons AND is in AQ2 zone
  # 4. Has sensitive equipment AND is OUTSIDE AQ2 zone
  def surge_protection_required?
    return true if has_lightning_protection

    if in_aq2_zone?
      return true if has_overhead_power_line
      return true if has_safety_critical_persons
    end

    if outside_aq2_zone?
      return true if has_sensitive_equipment
    end

    false
  end

  # Check if dwelling has surge protection installed
  def has_surge_protection?
    surge_protection_type = ItemType.find_by("LOWER(name) = ?", "surge protection")
    return false unless surge_protection_type

    Item.joins(breaker: { residual_current_device: { electrical_panel: :dwelling } })
        .where(dwellings: { id: id })
        .where(item_type: surge_protection_type)
        .exists?
  end

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
