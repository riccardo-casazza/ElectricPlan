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
[ 1.5, 2.5, 6, 10, 16 ].each do |section_value|
  Cable.find_or_create_by!(section: section_value)
end

puts "Seeded #{Cable.count} cable sections"

puts "Compliance rules are now defined in config/compliance_rules.yml"
