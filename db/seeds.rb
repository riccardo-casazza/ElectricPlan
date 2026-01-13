# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed ItemTypes
[
  "cooktop",
  "washing machine",
  "ev charger",
  "light",
  "socket",
  "oven",
  "dishwasher",
  "convector",
  "water heater",
  "roller shutters",
  "dryer",
  "freezer",
  "microwave",
  "A/C"
].each do |item_type_name|
  ItemType.find_or_create_by!(name: item_type_name)
end

puts "Seeded #{ItemType.count} item types"

# Seed ResidualCurrentDeviceTypes
[ "A", "AC", "F" ].each do |type_name|
  ResidualCurrentDeviceType.find_or_create_by!(name: type_name)
end

puts "Seeded #{ResidualCurrentDeviceType.count} residual current device types"

# Seed Cables
[ "1.5mm2", "2.5mm2", "6mm2", "10mm2", "16mm2" ].each do |section_name|
  Cable.find_or_create_by!(section: section_name)
end

puts "Seeded #{Cable.count} cable sections"

# Seed Rules
cooktop_rule_yaml = <<~YAML
  # Check if item type is cooktop and verify RCD type
  condition:
    item_type: cooktop
  validation:
    # Navigate from Item -> Breaker -> RCD -> RCD Type
    path: item.breaker.residual_current_device.residual_current_device_type.name
    must_equal: "A"
  error_message: "Cooktop must be connected to an RCD type A"
YAML

Rule.find_or_create_by!(
  description: "Cooktop should be connected to RCD type A",
  applies_to: "Item"
) do |rule|
  rule.rule = cooktop_rule_yaml
end

washing_machine_rule_yaml = <<~YAML
  # Check if item type is washing machine and verify RCD type
  condition:
    item_type: washing machine
  validation:
    # Navigate from Item -> Breaker -> RCD -> RCD Type
    path: item.breaker.residual_current_device.residual_current_device_type.name
    must_equal: "A"
  error_message: "Washing machine must be connected to an RCD type A"
YAML

Rule.find_or_create_by!(
  description: "Washing machine should be connected to RCD type A",
  applies_to: "Item"
) do |rule|
  rule.rule = washing_machine_rule_yaml
end

ev_charger_rule_yaml = <<~YAML
  # Check if item type is ev charger and verify RCD type
  condition:
    item_type: ev charger
  validation:
    # Navigate from Item -> Breaker -> RCD -> RCD Type
    path: item.breaker.residual_current_device.residual_current_device_type.name
    must_equal: "A"
  error_message: "EV charger must be connected to an RCD type A"
YAML

Rule.find_or_create_by!(
  description: "EV charger should be connected to RCD type A",
  applies_to: "Item"
) do |rule|
  rule.rule = ev_charger_rule_yaml
end

max_breakers_rule_yaml = <<~YAML
  # Check that each RCD has a maximum of 8 breakers
  validation:
    path: residual_current_device.breakers
    max_count: 8
  error_message: "RCD has too many breakers (maximum 8 allowed)"
YAML

Rule.find_or_create_by!(
  description: "Maximum 8 breakers per RCD",
  applies_to: "ResidualCurrentDevice"
) do |rule|
  rule.rule = max_breakers_rule_yaml
end

rcd_load_calculation_rule_yaml = <<~YAML
  # Check RCD max current capacity against connected load
  # Full load items (100%): ev charger, convector, water heater, A/C
  # Partial load items (50%): all other types
  validation:
    type: load_calculation
    full_load_types:
      - ev charger
      - convector
      - water heater
      - a/c
  error_message: "RCD max current insufficient for connected load"
YAML

Rule.find_or_create_by!(
  description: "RCD current capacity must handle connected load",
  applies_to: "ResidualCurrentDevice"
) do |rule|
  rule.rule = rcd_load_calculation_rule_yaml
end

light_only_rule_yaml = <<~YAML
  # Breakers with light items must only have light items
  validation:
    type: breaker_light_rules
    rule: only_lights
  error_message: "Breaker with lights must contain only light items"
YAML

Rule.find_or_create_by!(
  description: "Light breakers must contain only lights",
  applies_to: "Breaker"
) do |rule|
  rule.rule = light_only_rule_yaml
end

light_min_count_rule_yaml = <<~YAML
  # Breakers with light items must have at least 2 items
  validation:
    type: breaker_light_rules
    rule: min_count
    min_value: 2
  error_message: "Light breaker must have at least 2 items"
YAML

Rule.find_or_create_by!(
  description: "Light breakers must have minimum 2 items",
  applies_to: "Breaker"
) do |rule|
  rule.rule = light_min_count_rule_yaml
end

light_max_current_rule_yaml = <<~YAML
  # Breakers with light items must be maximum 16A
  validation:
    type: breaker_light_rules
    rule: max_current
    max_value: 16
  error_message: "Light breaker must be maximum 16A"
YAML

Rule.find_or_create_by!(
  description: "Light breakers must be maximum 16A",
  applies_to: "Breaker"
) do |rule|
  rule.rule = light_max_current_rule_yaml
end

light_max_count_rule_yaml = <<~YAML
  # Breakers with light items must have maximum 8 light items
  validation:
    type: breaker_light_rules
    rule: max_light_count
    max_value: 8
  error_message: "Light breaker must have maximum 8 light items"
YAML

Rule.find_or_create_by!(
  description: "Light breakers must have maximum 8 lights",
  applies_to: "Breaker"
) do |rule|
  rule.rule = light_max_count_rule_yaml
end

puts "Seeded #{Rule.count} compliance rules"
