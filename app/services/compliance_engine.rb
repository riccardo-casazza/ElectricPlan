require "ostruct"

class ComplianceEngine
  def initialize
    @rules = load_rules
  end

  # Check violations for a specific resource
  # Returns an array of ComplianceViolation objects
  def check_resource(resource)
    violations = []
    resource_type = resource.class.name

    # Get rules applicable to this resource type
    applicable_rules = rules_for_type(resource_type)

    applicable_rules.each do |rule_code, rule_config|
      # Check if the rule's condition is met
      next unless matches_condition?(resource, rule_config["condition"])

      # Validate the rule
      unless passes_validation?(resource, rule_config["validation"])
        violations << create_violation(rule_code, rule_config, resource)
      end
    end

    violations
  end

  # Check system-wide violations (not tied to specific resource)
  # Returns an array of ComplianceViolation objects
  def check_system
    violations = []
    system_rules = @rules["system_rules"] || {}

    system_rules.each do |rule_code, rule_config|
      unless passes_system_validation?(rule_config["validation"])
        violations << create_system_violation(rule_code, rule_config)
      end
    end

    violations
  end

  # Check upstream violations (violations that would affect this resource)
  # For example, if a Breaker has too many items, all those Items are affected
  def check_upstream_violations(resource)
    case resource.class.name
    when "Item"
      # Check if parent Breaker has violations
      resource.breaker&.compliance_violations || []
    when "Breaker"
      # Check if parent RCD has violations
      resource.residual_current_device&.compliance_violations || []
    else
      []
    end
  end

  # Check downstream violations (violations in child resources caused by this resource)
  # For example, if an RCD's type is wrong, all connected Items might have violations
  def check_downstream_violations(resource)
    violations = []

    case resource.class.name
    when "ElectricalPanel"
      # Check all RCDs under this panel (including their downstream violations)
      resource.residual_current_devices.each do |rcd|
        violations.concat(rcd.compliance_violations)
        violations.concat(rcd.downstream_violations)
      end
    when "ResidualCurrentDevice"
      # Check all breakers under this RCD (including their downstream violations)
      resource.breakers.each do |breaker|
        violations.concat(breaker.compliance_violations)
        violations.concat(breaker.downstream_violations)
      end
    when "Breaker"
      # Check all items on this breaker
      resource.items.each do |item|
        violations.concat(item.compliance_violations)
      end
    end

    violations
  end

  private

  def load_rules
    file_path = Rails.root.join("config", "compliance_rules.yml")
    YAML.load_file(file_path, permitted_classes: [Symbol])
  rescue => e
    Rails.logger.error "Failed to load compliance rules: #{e.message}"
    {}
  end

  def rules_for_type(resource_type)
    all_rules = {}

    # Collect all rules that apply to this resource type
    @rules.each do |category_key, category_rules|
      next unless category_rules.is_a?(Hash)

      category_rules.each do |rule_code, rule_config|
        if rule_config["applies_to"] == resource_type
          all_rules[rule_code] = rule_config
        end
      end
    end

    all_rules
  end

  def matches_condition?(resource, condition)
    return true if condition.nil?

    condition_type = condition["type"]

    case condition_type
    when "has_light_items"
      # Check if resource has any light items
      return false unless resource.respond_to?(:items)
      resource.items.joins(:item_type).where(item_types: { name: "light" }).exists?

    when "has_socket_items"
      # Check if resource has any socket items
      return false unless resource.respond_to?(:items)
      resource.items.joins(:item_type).where(item_types: { name: "socket" }).exists?

    when "socket_breaker_16a"
      # Check if this is a 16A breaker with sockets
      return false unless resource.respond_to?(:items) && resource.respond_to?(:output_max_current)
      has_sockets = resource.items.joins(:item_type).where(item_types: { name: "socket" }).exists?
      has_sockets && resource.output_max_current == 16

    when "socket_breaker_20a"
      # Check if this is a 20A breaker with sockets
      return false unless resource.respond_to?(:items) && resource.respond_to?(:output_max_current)
      has_sockets = resource.items.joins(:item_type).where(item_types: { name: "socket" }).exists?
      has_sockets && resource.output_max_current == 20

    when "item_type_equals"
      # Check if item's type matches the specified value
      return false unless resource.respond_to?(:item_type)
      resource.item_type.name.downcase == condition["value"].to_s.downcase

    when "kitchen_socket_breaker"
      # Check if this is a socket breaker serving a kitchen
      return false unless resource.respond_to?(:items)
      has_sockets = resource.items.joins(:item_type).where(item_types: { name: "socket" }).exists?
      return false unless has_sockets

      # Check if any of the items are in a kitchen
      resource.items.joins(:room).where(rooms: { is_kitchen: true }).exists?

    when "has_shutter_items"
      # Check if resource has any roller shutter items
      return false unless resource.respond_to?(:items)
      resource.items.joins(:item_type).where(item_types: { name: "roller shutters" }).exists?

    else
      true
    end
  end

  def passes_validation?(resource, validation)
    return true if validation.nil?

    validation_type = validation["type"]

    case validation_type
    when "exclusive_type"
      validate_exclusive_type(resource, validation)
    when "max_count"
      validate_max_count(resource, validation)
    when "max_attribute"
      validate_max_attribute(resource, validation)
    when "association_attribute"
      validate_association_attribute(resource, validation)
    when "association_count"
      validate_association_count(resource, validation)
    when "load_calculation"
      validate_load_calculation(resource, validation)
    when "attribute_in_list"
      validate_attribute_in_list(resource, validation)
    when "min_cable_section"
      validate_min_cable_section(resource, validation)
    else
      true
    end
  end

  def passes_system_validation?(validation)
    return true if validation.nil?

    validation_type = validation["type"]

    case validation_type
    when "min_light_breakers"
      min_value = validation["min_value"] || 2
      light_breakers_count = Breaker.joins(items: :item_type)
                                     .where(item_types: { name: "light" })
                                     .distinct
                                     .count
      light_breakers_count >= min_value

    when "min_shutter_breakers"
      min_value = validation["min_value"] || 1
      shutter_breakers_count = Breaker.joins(items: :item_type)
                                       .where(item_types: { name: "roller shutters" })
                                       .distinct
                                       .count
      shutter_breakers_count >= min_value

    else
      true
    end
  end

  def validate_exclusive_type(resource, validation)
    required_type = validation["required_type"]
    return true unless resource.respond_to?(:items)

    # All items must be of the required type
    non_matching_items = resource.items.joins(:item_type).where.not(item_types: { name: required_type })
    non_matching_items.empty?
  end

  def validate_max_count(resource, validation)
    attribute = validation["attribute"]
    max_value = validation["max_value"]

    # Get the collection (e.g., light_items, socket_items)
    items = case attribute
    when "light_items"
      resource.items.joins(:item_type).where(item_types: { name: "light" })
    when "socket_items"
      resource.items.joins(:item_type).where(item_types: { name: "socket" })
    else
      return true
    end

    items.count <= max_value
  end

  def validate_max_attribute(resource, validation)
    attribute = validation["attribute"]
    max_value = validation["max_value"]

    actual_value = resource.send(attribute)
    actual_value <= max_value
  rescue
    true
  end

  def validate_association_attribute(resource, validation)
    path = validation["path"]
    expected_value = validation["must_equal"]

    actual_value = get_nested_value(resource, path)
    return true if actual_value.nil?

    actual_value.to_s.downcase == expected_value.to_s.downcase
  end

  def validate_association_count(resource, validation)
    association = validation["association"]
    max_count = validation["max_count"]

    return true unless resource.respond_to?(association)

    actual_count = resource.send(association).count
    actual_count <= max_count
  end

  def validate_load_calculation(resource, validation)
    return true unless resource.is_a?(ResidualCurrentDevice)

    full_load_types = validation["full_load_types"] || []
    breakers = resource.breakers.includes(items: :item_type)

    full_load_sum = 0
    partial_load_sum = 0

    breakers.each do |breaker|
      next if breaker.items.empty?

      has_full_load_item = breaker.items.any? do |item|
        full_load_types.include?(item.item_type.name.downcase)
      end

      if has_full_load_item
        full_load_sum += breaker.output_max_current
      else
        partial_load_sum += breaker.output_max_current
      end
    end

    total_required = full_load_sum + (partial_load_sum * 0.5)
    resource.output_max_current >= total_required
  end

  def validate_attribute_in_list(resource, validation)
    attribute = validation["attribute"]
    allowed_values = validation["allowed_values"]

    actual_value = resource.send(attribute)
    allowed_values.include?(actual_value)
  rescue
    true
  end

  def validate_min_cable_section(resource, validation)
    path = validation["path"]
    min_section = validation["min_section"]

    actual_value = get_nested_value(resource, path)
    return true if actual_value.nil?

    # Convert to float for comparison (handles both numeric and string inputs)
    min_value = min_section.to_f
    actual_float = actual_value.to_f

    return true if min_value.zero? || actual_float.zero?

    # Actual cable section must be >= minimum required
    actual_float >= min_value
  end

  def get_nested_value(object, path)
    return nil unless object

    parts = path.to_s.split(".")
    parts.shift if parts.first&.downcase == object.class.name.downcase

    parts.reduce(object) do |obj, method|
      return nil if obj.nil?
      begin
        obj.send(method)
      rescue
        nil
      end
    end
  end

  def create_violation(rule_code, rule_config, resource)
    context = build_context(resource, rule_config["validation"])

    ComplianceViolation.new(
      rule_code: rule_code,
      severity: rule_config["severity"] || "error",
      message: rule_config["message"],
      help: rule_config["help"],
      resource: resource,
      context: context
    )
  end

  def create_system_violation(rule_code, rule_config)
    context = {}

    # Add specific context for system-level violations
    validation_type = rule_config["validation"]["type"]

    if validation_type == "min_light_breakers"
      min_value = rule_config["validation"]["min_value"] || 2
      actual_count = Breaker.joins(items: :item_type)
                            .where(item_types: { name: "light" })
                            .distinct
                            .count
      context = {
        actual_count: actual_count,
        min_value: min_value
      }
    elsif validation_type == "min_shutter_breakers"
      min_value = rule_config["validation"]["min_value"] || 1
      actual_count = Breaker.joins(items: :item_type)
                            .where(item_types: { name: "roller shutters" })
                            .distinct
                            .count
      context = {
        actual_count: actual_count,
        min_value: min_value
      }
    end

    # Create a pseudo-resource for system-level violations
    system_resource = OpenStruct.new(id: 0, class: OpenStruct.new(name: "System"))

    ComplianceViolation.new(
      rule_code: rule_code,
      severity: rule_config["severity"] || "error",
      message: rule_config["message"],
      help: rule_config["help"],
      resource: system_resource,
      context: context
    )
  end

  def build_context(resource, validation)
    context = {}
    return context if validation.nil?

    validation_type = validation["type"]

    case validation_type
    when "exclusive_type"
      # Add non-matching items to context
      if resource.respond_to?(:items)
        required_type = validation["required_type"]
        non_matching_items = resource.items.joins(:item_type)
                                  .where.not(item_types: { name: required_type })
                                  .map { |item| item.item_type.name }

        # Use appropriate context key based on required type
        context_key = "non_#{required_type}_items".to_sym
        context[context_key] = non_matching_items.join(", ")

        # Keep backwards compatibility for light breakers
        if required_type == "light"
          context[:non_light_items] = non_matching_items.join(", ")
        elsif required_type == "socket"
          context[:non_socket_items] = non_matching_items.join(", ")
        end
      end

    when "max_count"
      attribute = validation["attribute"]
      max_value = validation["max_value"]

      actual_count = case attribute
      when "light_items"
        resource.items.joins(:item_type).where(item_types: { name: "light" }).count
      when "socket_items"
        resource.items.joins(:item_type).where(item_types: { name: "socket" }).count
      else
        0
      end

      context[:actual_count] = actual_count
      context[:max_value] = max_value

    when "max_attribute"
      attribute = validation["attribute"]
      max_value = validation["max_value"]
      actual_value = resource.send(attribute) rescue nil

      context[:actual_value] = actual_value
      context[:max_value] = max_value

    when "attribute_in_list"
      attribute = validation["attribute"]
      allowed_values = validation["allowed_values"]
      actual_value = resource.send(attribute) rescue nil

      context[:actual_value] = actual_value
      context[:allowed_values] = allowed_values.join(", ")

    when "association_attribute"
      path = validation["path"]
      expected_value = validation["must_equal"]
      actual_value = get_nested_value(resource, path)

      context[:actual_value] = actual_value
      context[:expected_value] = expected_value

    when "association_count"
      association = validation["association"]
      max_count = validation["max_count"]
      actual_count = resource.send(association).count rescue 0

      context[:actual_count] = actual_count
      context[:max_count] = max_count

    when "load_calculation"
      full_load_types = validation["full_load_types"] || []
      breakers = resource.breakers.includes(items: :item_type)

      full_load_sum = 0
      partial_load_sum = 0

      breakers.each do |breaker|
        next if breaker.items.empty?

        has_full_load_item = breaker.items.any? do |item|
          full_load_types.include?(item.item_type.name.downcase)
        end

        if has_full_load_item
          full_load_sum += breaker.output_max_current
        else
          partial_load_sum += breaker.output_max_current
        end
      end

      total_required = full_load_sum + (partial_load_sum * 0.5)

      context[:rcd_current] = resource.output_max_current
      context[:required_current] = total_required.round(1)
      context[:full_load_sum] = full_load_sum
      context[:partial_load_sum] = partial_load_sum

    when "min_cable_section"
      path = validation["path"]
      min_section = validation["min_section"]
      actual_value = get_nested_value(resource, path)

      context[:actual_value] = actual_value
      context[:min_section] = min_section
    end

    context
  end
end
