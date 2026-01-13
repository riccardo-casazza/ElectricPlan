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
  "microwave"
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

puts "Seeded #{Rule.count} compliance rules"
