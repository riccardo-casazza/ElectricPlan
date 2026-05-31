require "ostruct"
require_relative "compliance/item_types"
require_relative "compliance/base_validator"
require_relative "compliance/validators"

class ComplianceEngine
  include Compliance

  def initialize
    @rules = load_rules
  end

  def check_resource(resource)
    rules_for_type(resource.class.name).filter_map do |rule_code, rule_config|
      next unless matches_condition?(resource, rule_config["condition"])
      create_violation(rule_code, rule_config, resource) unless passes_validation?(resource, rule_config["validation"])
    end
  end

  def check_system
    (@rules["system_rules"] || {}).filter_map do |rule_code, rule_config|
      create_system_violation(rule_code, rule_config) unless passes_system_validation?(rule_config["validation"])
    end
  end

  def check_dwelling(dwelling)
    rules_for_type("Dwelling").filter_map do |rule_code, rule_config|
      create_dwelling_violation(rule_code, rule_config, dwelling) unless passes_dwelling_validation?(dwelling, rule_config["validation"])
    end
  end

  def check_upstream_violations(resource)
    case resource.class.name
    when "Item" then resource.breaker&.compliance_violations || []
    when "Breaker" then resource.residual_current_device&.compliance_violations || []
    else []
    end
  end

  def check_downstream_violations(resource)
    case resource.class.name
    when "ElectricalPanel"
      resource.residual_current_devices.flat_map { |rcd| rcd.compliance_violations + rcd.downstream_violations }
    when "ResidualCurrentDevice"
      resource.breakers.flat_map { |b| b.compliance_violations + b.downstream_violations }
    when "Breaker"
      resource.items.flat_map(&:compliance_violations)
    else []
    end
  end

  private

  def load_rules
    YAML.load_file(Rails.root.join("config", "compliance_rules.yml"), permitted_classes: [Symbol])
  rescue StandardError => e
    Rails.logger.error "Failed to load compliance rules: #{e.message}"
    {}
  end

  def rules_for_type(type)
    @rules.each_with_object({}) do |(_, rules), acc|
      next unless rules.is_a?(Hash)
      rules.each { |code, config| acc[code] = config if config["applies_to"] == type }
    end
  end

  # ========================================
  # CONDITIONS
  # ========================================

  def matches_condition?(resource, condition)
    return true if condition.nil?
    case condition["type"]
    when "has_light_items" then has_items?(resource, ITEM_TYPES[:light])
    when "has_socket_items" then has_items?(resource, ITEM_TYPES[:socket])
    when "has_shutter_items" then has_items?(resource, ITEM_TYPES[:shutter])
    when "has_convector_items" then has_items?(resource, ITEM_TYPES[:convector])
    when "has_cooktop_items" then has_items?(resource, ITEM_TYPES[:cooktop])
    when "has_ev_charger_items" then has_items?(resource, ITEM_TYPES[:ev_charger])
    when "has_water_heater_items" then has_items?(resource, ITEM_TYPES[:water_heater])
    when "has_freezer_items" then has_items?(resource, ITEM_TYPES[:freezer])
    when "has_high_power_appliance_items" then has_any_items?(resource, HIGH_POWER_APPLIANCES)
    when "socket_breaker_16a" then has_items?(resource, ITEM_TYPES[:socket]) && resource.output_max_current == 16
    when "socket_breaker_20a" then has_items?(resource, ITEM_TYPES[:socket]) && resource.output_max_current == 20
    when "kitchen_socket_breaker"
      has_items?(resource, ITEM_TYPES[:socket]) && resource.items.joins(:room).where(rooms: { is_kitchen: true }).exists?
    when "item_type_equals"
      resource.respond_to?(:item_type) && resource.item_type.name.downcase == condition["value"].to_s.downcase
    when "room_type_equals"
      resource.respond_to?(:room_type) && resource.room_type.to_s.downcase == condition["value"].to_s.downcase
    when "room_larger_than"
      resource.respond_to?(:surface_area) && resource.surface_area &&
        !%w[living_room bedroom kitchen].include?(resource.room_type.to_s.downcase) &&
        resource.surface_area.to_f > condition["min_area"].to_f
    else true
    end
  end

  def has_items?(resource, type)
    resource.respond_to?(:items) && resource.items.joins(:item_type).where("LOWER(item_types.name) = ?", type.downcase).exists?
  end

  def has_any_items?(resource, types)
    resource.respond_to?(:items) && resource.items.joins(:item_type).where("LOWER(item_types.name) IN (?)", types.map(&:downcase)).exists?
  end

  # ========================================
  # VALIDATION
  # ========================================

  def passes_validation?(resource, validation)
    return true if validation.nil?
    validator = Validators.for(validation["type"], resource, validation)
    validator ? validator.valid? : true
  end

  def passes_system_validation?(validation)
    return true if validation.nil?
    case validation["type"]
    when "min_light_breakers"
      breakers_with_type(ITEM_TYPES[:light]) >= (validation["min_value"] || 2)
    when "min_shutter_breakers"
      breakers_with_type(ITEM_TYPES[:shutter]) >= (validation["min_value"] || 1)
    when "min_appliance_circuits"
      breakers_with_any_type(validation["appliance_types"] || HIGH_POWER_APPLIANCES) >= (validation["min_value"] || 3)
    else true
    end
  end

  def passes_dwelling_validation?(dwelling, validation)
    return true if validation.nil?
    case validation["type"]
    when "min_shutter_breakers"
      dwelling_breakers_with_type(dwelling, ITEM_TYPES[:shutter]) >= (validation["min_value"] || 1)
    when "min_appliance_circuits"
      dwelling_breakers_with_any_type(dwelling, validation["appliance_types"] || HIGH_POWER_APPLIANCES) >= (validation["min_value"] || 3)
    when "surge_protection_required"
      !dwelling.surge_protection_required? || dwelling.has_surge_protection?
    when "min_rcd_count"
      dwelling_rcds(dwelling) >= (validation["min_value"] || 2)
    when "min_rcd_type_count"
      dwelling_rcds_of_type(dwelling, validation["rcd_type"]) >= (validation["min_value"] || 1)
    else true
    end
  end

  # ========================================
  # QUERY HELPERS
  # ========================================

  def breakers_with_type(type)
    Breaker.joins(items: :item_type).where("LOWER(item_types.name) = ?", type.downcase).distinct.count
  end

  def breakers_with_any_type(types)
    Breaker.joins(items: :item_type).where("LOWER(item_types.name) IN (?)", types.map(&:downcase)).distinct.count
  end

  def dwelling_breakers_with_type(dwelling, type)
    Breaker.joins(residual_current_device: { electrical_panel: :dwelling }, items: :item_type)
           .where(dwellings: { id: dwelling.id }).where("LOWER(item_types.name) = ?", type.downcase).distinct.count
  end

  def dwelling_breakers_with_any_type(dwelling, types)
    Breaker.joins(residual_current_device: { electrical_panel: :dwelling }, items: :item_type)
           .where(dwellings: { id: dwelling.id }).where("LOWER(item_types.name) IN (?)", types.map(&:downcase)).distinct.count
  end

  def dwelling_rcds(dwelling)
    ResidualCurrentDevice.joins(electrical_panel: :dwelling).where(dwellings: { id: dwelling.id }).count
  end

  def dwelling_rcds_of_type(dwelling, type)
    ResidualCurrentDevice.joins(electrical_panel: :dwelling, residual_current_device_type: {})
                         .where(dwellings: { id: dwelling.id }, residual_current_device_types: { name: type }).count
  end

  # ========================================
  # VIOLATION CREATION
  # ========================================

  def create_violation(rule_code, rule_config, resource)
    validator = Validators.for(rule_config["validation"]["type"], resource, rule_config["validation"])
    ComplianceViolation.new(
      rule_code: rule_code, severity: rule_config["severity"] || "error",
      message: rule_config["message"], help: rule_config["help"],
      resource: resource, context: validator&.context || {}
    )
  end

  def create_system_violation(rule_code, rule_config)
    ComplianceViolation.new(
      rule_code: rule_code, severity: rule_config["severity"] || "error",
      message: rule_config["message"], help: rule_config["help"],
      resource: OpenStruct.new(id: 0, class: OpenStruct.new(name: "System")),
      context: build_system_context(rule_config["validation"])
    )
  end

  def create_dwelling_violation(rule_code, rule_config, dwelling)
    ComplianceViolation.new(
      rule_code: rule_code, severity: rule_config["severity"] || "error",
      message: rule_config["message"], help: rule_config["help"],
      resource: dwelling, context: build_dwelling_context(dwelling, rule_config["validation"])
    )
  end

  def build_system_context(validation)
    case validation["type"]
    when "min_light_breakers"
      { actual_count: breakers_with_type(ITEM_TYPES[:light]), min_value: validation["min_value"] || 2 }
    when "min_shutter_breakers"
      { actual_count: breakers_with_type(ITEM_TYPES[:shutter]), min_value: validation["min_value"] || 1 }
    when "min_appliance_circuits"
      types = validation["appliance_types"] || HIGH_POWER_APPLIANCES
      { actual_count: breakers_with_any_type(types), min_value: validation["min_value"] || 3, appliance_types: types.join(", ") }
    else {}
    end
  end

  def build_dwelling_context(dwelling, validation)
    case validation["type"]
    when "min_shutter_breakers"
      { actual_count: dwelling_breakers_with_type(dwelling, ITEM_TYPES[:shutter]), min_value: validation["min_value"] || 1 }
    when "min_appliance_circuits"
      types = validation["appliance_types"] || HIGH_POWER_APPLIANCES
      { actual_count: dwelling_breakers_with_any_type(dwelling, types), min_value: validation["min_value"] || 3, appliance_types: types.join(", ") }
    when "surge_protection_required"
      { reason: surge_protection_reason(dwelling) }
    when "min_rcd_count"
      { actual_count: dwelling_rcds(dwelling), min_value: validation["min_value"] || 2 }
    when "min_rcd_type_count"
      { actual_count: dwelling_rcds_of_type(dwelling, validation["rcd_type"]), min_value: validation["min_value"] || 1, rcd_type: validation["rcd_type"] }
    else {}
    end
  end

  def surge_protection_reason(dwelling)
    reasons = []
    reasons << "has lightning protection" if dwelling.has_lightning_protection
    if dwelling.in_aq2_zone?
      reasons << "overhead power line in AQ2 zone" if dwelling.has_overhead_power_line
      reasons << "safety-critical persons in AQ2 zone" if dwelling.has_safety_critical_persons
    end
    reasons << "sensitive equipment outside AQ2 zone" if dwelling.outside_aq2_zone? && dwelling.has_sensitive_equipment
    reasons.join(", ")
  end
end
