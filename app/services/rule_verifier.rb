class RuleVerifier
  def initialize(rule)
    @rule = rule
    @violations = []
  end

  def verify
    return { success: false, error: "Rule YAML is invalid" } unless parse_rule_yaml

    # Clear previous violations for this rule
    @rule.rule_violations.destroy_all

    # Get all resources of the type this rule applies to
    resources = get_applicable_resources

    resources.each do |resource|
      check_resource(resource)
    end

    # If no violations found, create a "pass" marker so we know verification ran
    if @violations.empty? && resources.any?
      @rule.rule_violations.create!(
        resource_type: "System",
        resource_id: 0,
        severity: "info",
        message: "All resources comply with this rule",
        resolved: true,  # Mark as resolved so it shows as "pass"
        context: {
          verified_at: Time.current,
          resources_checked: resources.count
        }
      )
    end

    {
      success: true,
      total_checked: resources.count,
      violations_count: @violations.count,
      violations: @violations
    }
  rescue => e
    { success: false, error: e.message }
  end

  private

  def parse_rule_yaml
    @rule_data = YAML.safe_load(@rule.rule, permitted_classes: [ Symbol ])
    true
  rescue => e
    false
  end

  def get_applicable_resources
    @rule.applies_to.constantize.all
  rescue
    []
  end

  def check_resource(resource)
    # Check if resource matches the condition
    return unless matches_condition?(resource)

    # Validate the rule
    unless passes_validation?(resource)
      create_violation(resource)
    end
  end

  def matches_condition?(resource)
    return true unless @rule_data["condition"]

    condition = @rule_data["condition"]

    # Example: condition: { item_type: "cooktop" }
    condition.all? do |key, expected_value|
      # For associations, try both the direct value and .name
      actual_value = get_nested_value(resource, key)

      # If the value is an ActiveRecord object, try to get its name
      if actual_value.is_a?(ApplicationRecord)
        actual_value = actual_value.try(:name) || actual_value.to_s
      end

      actual_value.to_s.downcase == expected_value.to_s.downcase
    end
  end

  def passes_validation?(resource)
    validation = @rule_data["validation"]
    return true unless validation

    # Handle load_calculation validation for RCD current capacity
    if validation["type"] == "load_calculation"
      return validate_rcd_load_calculation(resource, validation)
    end

    # Handle max_count validation
    if validation["max_count"]
      path = validation["path"]
      max_count = validation["max_count"]

      actual_value = get_nested_value(resource, path)
      return true unless actual_value

      # Get count if it's a collection
      count = actual_value.respond_to?(:count) ? actual_value.count : 0
      return count <= max_count
    end

    # Handle must_equal validation
    path = validation["path"]
    expected_value = validation["must_equal"]

    actual_value = get_nested_value(resource, path)

    actual_value.to_s.downcase == expected_value.to_s.downcase
  end

  def validate_rcd_load_calculation(rcd, validation)
    full_load_types = validation["full_load_types"] || []

    # Get all breakers for this RCD with their items
    breakers = rcd.breakers.includes(items: :item_type)

    full_load_sum = 0
    partial_load_sum = 0

    breakers.each do |breaker|
      # Skip breakers with no items
      next if breaker.items.empty?

      # Check if any item on this breaker is a full load type
      has_full_load_item = breaker.items.any? do |item|
        full_load_types.include?(item.item_type.name.downcase)
      end

      if has_full_load_item
        full_load_sum += breaker.output_max_current
      else
        partial_load_sum += breaker.output_max_current
      end
    end

    # Apply 0.5 multiplier to partial load
    total_required = full_load_sum + (partial_load_sum * 0.5)

    # RCD max current must be >= total required
    rcd.output_max_current >= total_required
  end

  def get_nested_value(object, path)
    return nil unless object

    # Handle dot notation: "item.breaker.residual_current_device.residual_current_device_type.name"
    parts = path.to_s.split(".")

    # Skip the first part if it's the resource name itself (e.g., "item")
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

  def create_violation(resource)
    error_message = @rule_data.dig("error_message") || "Rule validation failed"

    context = {
      resource_name: resource.try(:name) || resource.id,
      checked_at: Time.current
    }

    # Add count information if this is a max_count violation
    if @rule_data.dig("validation", "max_count")
      path = @rule_data.dig("validation", "path")
      actual_value = get_nested_value(resource, path)
      if actual_value&.respond_to?(:count)
        context[:actual_count] = actual_value.count
        context[:max_count] = @rule_data.dig("validation", "max_count")
      end
    end

    # Add load calculation details if this is a load_calculation violation
    if @rule_data.dig("validation", "type") == "load_calculation"
      full_load_types = @rule_data.dig("validation", "full_load_types") || []
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

      context[:rcd_max_current] = resource.output_max_current
      context[:full_load_sum] = full_load_sum
      context[:partial_load_sum] = partial_load_sum
      context[:total_required] = total_required.round(1)
    end

    violation = @rule.rule_violations.create!(
      resource_type: resource.class.name,
      resource_id: resource.id,
      severity: "error",
      message: error_message,
      context: context
    )

    @violations << violation
  end
end
