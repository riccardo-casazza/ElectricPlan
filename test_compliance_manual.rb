#!/usr/bin/env ruby
# Manual compliance rule verification script
ENV["RAILS_ENV"] = "test"
require_relative "config/environment"

puts "=" * 80
puts "MANUAL COMPLIANCE RULES TESTING"
puts "=" * 80
puts

engine = ComplianceEngine.new

# Test counters
total_tests = 0
passed_tests = 0
failed_tests = 0

def test(name, &block)
  print "Testing #{name}... "
  begin
    result = block.call
    if result
      puts "✓ PASS"
      true
    else
      puts "✗ FAIL"
      false
    end
  rescue => e
    puts "✗ ERROR: #{e.message}"
    puts e.backtrace.first(3)
    false
  end
end

# Setup test data
ActiveRecord::Base.transaction do
  puts "Setting up test data..."

  floor = Floor.create!(name: "Test Floor")
  room = Room.create!(name: "Test Room", floor: floor)
  kitchen = Room.create!(name: "Kitchen", floor: floor, is_kitchen: true)

  cable_1_5 = Cable.find_or_create_by!(section: 1.5)
  cable_2_5 = Cable.find_or_create_by!(section: 2.5)
  cable_6 = Cable.find_or_create_by!(section: 6)

  dwelling = Dwelling.create!(name: "Test House")
  panel = ElectricalPanel.create!(name: "Test Panel", dwelling: dwelling, room: room, input_cable: cable_6)
  rcd_type = ResidualCurrentDeviceType.first || ResidualCurrentDeviceType.create!(name: "Type A")
  rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 1, position: 1)

  light_type = ItemType.find_or_create_by!(name: "light")
  socket_type = ItemType.find_or_create_by!(name: "socket")
  convector_type = ItemType.find_or_create_by!(name: "convector")

  puts "✓ Test data created\n\n"

  # TEST 1: Light breaker with non-light items (should fail)
  total_tests += 1
  passed_tests += 1 if test("light_only rule - should detect non-light items") do
    breaker = Breaker.create!(residual_current_device: rcd, output_max_current: 16, position: 1)
    Item.create!(breaker: breaker, room: room, name: "Light 1", item_type: light_type)
    Item.create!(breaker: breaker, room: room, name: "Socket 1", item_type: socket_type)

    violations = engine.check_resource(breaker)
    violations.any? { |v| v.rule_code.to_s == "light_only" }
  end

  # TEST 2: Light breaker with only lights (should pass)
  total_tests += 1
  passed_tests += 1 if test("light_only rule - should pass with only lights") do
    breaker = Breaker.create!(residual_current_device: rcd, output_max_current: 16, position: 2)
    Item.create!(breaker: breaker, room: room, name: "Light 1", item_type: light_type)
    Item.create!(breaker: breaker, room: room, name: "Light 2", item_type: light_type)

    violations = engine.check_resource(breaker)
    violations.none? { |v| v.rule_code.to_s == "light_only" }
  end

  # TEST 3: Light breaker exceeding 8 lights (should fail)
  total_tests += 1
  passed_tests += 1 if test("light_max_count rule - should detect >8 lights") do
    breaker = Breaker.create!(residual_current_device: rcd, output_max_current: 16, position: 3)
    9.times { |i| Item.create!(breaker: breaker, room: room, name: "Light #{i+1}", item_type: light_type) }

    violations = engine.check_resource(breaker)
    violations.any? { |v| v.rule_code.to_s == "light_max_count" }
  end

  # TEST 4: Light breaker exceeding 16A (should fail)
  total_tests += 1
  passed_tests += 1 if test("light_max_current rule - should detect >16A") do
    breaker = Breaker.create!(residual_current_device: rcd, output_max_current: 20, position: 4)
    Item.create!(breaker: breaker, room: room, name: "Light 1", item_type: light_type)

    violations = engine.check_resource(breaker)
    violations.any? { |v| v.rule_code.to_s == "light_max_current" }
  end

  # TEST 5: Convector breaker with insufficient current for power (should fail)
  # 2000W needs at least 16A but we're using 10A
  total_tests += 1
  passed_tests += 1 if test("convector_power_current_cable rule - should detect insufficient current") do
    breaker = Breaker.create!(residual_current_device: rcd, output_max_current: 10, position: 5)
    Item.create!(breaker: breaker, room: room, name: "Convector 1", item_type: convector_type, power_watts: 2000, input_cable: cable_2_5)

    violations = engine.check_resource(breaker)
    violations.any? { |v| v.rule_code.to_s == "convector_power_current_cable" }
  end

  # TEST 6: Convector breaker with power exceeding max tier (>7250W should fail)
  total_tests += 1
  passed_tests += 1 if test("convector_power_current_cable rule - should detect >7250W") do
    breaker = Breaker.create!(residual_current_device: rcd, output_max_current: 32, position: 6)
    Item.create!(breaker: breaker, room: room, name: "Convector 1", item_type: convector_type, power_watts: 4000, input_cable: cable_2_5)
    Item.create!(breaker: breaker, room: room, name: "Convector 2", item_type: convector_type, power_watts: 4000, input_cable: cable_2_5)

    violations = engine.check_resource(breaker)
    violations.any? { |v| v.rule_code.to_s == "convector_power_current_cable" }
  end

  # TEST 7: Kitchen socket breaker exceeding max count (should fail)
  total_tests += 1
  passed_tests += 1 if test("kitchen_socket_max_count rule - should detect >6 sockets") do
    breaker = Breaker.create!(residual_current_device: rcd, output_max_current: 20, position: 7)
    7.times { |i| Item.create!(breaker: breaker, room: kitchen, name: "Kitchen Socket #{i+1}", item_type: socket_type) }

    violations = engine.check_resource(breaker)
    violations.any? { |v| v.rule_code.to_s == "kitchen_socket_max_count" }
  end

  # TEST 8: System rules - insufficient light breakers
  total_tests += 1
  passed_tests += 1 if test("min_light_circuits rule - should detect insufficient breakers") do
    Breaker.destroy_all
    breaker = Breaker.create!(residual_current_device: rcd, output_max_current: 16, position: 1)
    Item.create!(breaker: breaker, room: room, name: "Light 1", item_type: light_type)

    violations = engine.check_system
    violations.any? { |v| v.rule_code.to_s == "min_light_circuits" }
  end

  # TEST 9: System rules - missing shutter breaker
  total_tests += 1
  passed_tests += 1 if test("min_shutter_circuits rule - should detect missing shutter") do
    Breaker.destroy_all

    violations = engine.check_system
    violations.any? { |v| v.rule_code.to_s == "min_shutter_circuits" }
  end

  # TEST 10: System rules - insufficient appliance circuits
  total_tests += 1
  passed_tests += 1 if test("min_appliance_circuits rule - should detect <3 circuits") do
    Breaker.destroy_all
    dishwasher_type = ItemType.find_or_create_by!(name: "dishwasher")
    breaker = Breaker.create!(residual_current_device: rcd, output_max_current: 20, position: 1)
    Item.create!(breaker: breaker, room: kitchen, name: "Dishwasher", item_type: dishwasher_type)

    violations = engine.check_system
    violations.any? { |v| v.rule_code.to_s == "min_appliance_circuits" }
  end

  # ========================================
  # NEW RULES TESTS (NF C 15-100 Aug 2024)
  # ========================================

  # TEST 11: Dwelling must have minimum 2 RCDs
  total_tests += 1
  passed_tests += 1 if test("min_rcds rule - should detect <2 RCDs") do
    # Create a new dwelling with only 1 RCD
    test_dwelling = Dwelling.create!(name: "Test Dwelling Single RCD")
    test_panel = ElectricalPanel.create!(name: "Single RCD Panel", dwelling: test_dwelling, room: room, input_cable: cable_6)
    ResidualCurrentDevice.create!(electrical_panel: test_panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 1, position: 1)

    violations = engine.check_dwelling(test_dwelling)
    violations.any? { |v| v.rule_code.to_s == "min_rcds" }
  end

  # TEST 12: Dwelling with 2+ RCDs should pass min_rcds
  total_tests += 1
  passed_tests += 1 if test("min_rcds rule - should pass with 2 RCDs") do
    test_dwelling = Dwelling.create!(name: "Test Dwelling Two RCDs")
    test_panel = ElectricalPanel.create!(name: "Two RCD Panel", dwelling: test_dwelling, room: room, input_cable: cable_6)
    ResidualCurrentDevice.create!(electrical_panel: test_panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 1, position: 1)
    ResidualCurrentDevice.create!(electrical_panel: test_panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 1, position: 2)

    violations = engine.check_dwelling(test_dwelling)
    violations.none? { |v| v.rule_code.to_s == "min_rcds" }
  end

  # TEST 13: Dwelling must have at least 1 RCD type A
  total_tests += 1
  passed_tests += 1 if test("min_rcd_type_a rule - should detect no type A RCD") do
    rcd_type_ac = ResidualCurrentDeviceType.find_or_create_by!(name: "AC")

    test_dwelling = Dwelling.create!(name: "Test Dwelling No Type A")
    test_panel = ElectricalPanel.create!(name: "No Type A Panel", dwelling: test_dwelling, room: room, input_cable: cable_6)
    ResidualCurrentDevice.create!(electrical_panel: test_panel, output_max_current: 40, residual_current_device_type: rcd_type_ac, row_number: 1, position: 1)
    ResidualCurrentDevice.create!(electrical_panel: test_panel, output_max_current: 40, residual_current_device_type: rcd_type_ac, row_number: 1, position: 2)

    violations = engine.check_dwelling(test_dwelling)
    violations.any? { |v| v.rule_code.to_s == "min_rcd_type_a" }
  end

  # TEST 14: Dwelling with type A RCD should pass
  total_tests += 1
  passed_tests += 1 if test("min_rcd_type_a rule - should pass with type A RCD") do
    rcd_type_a = ResidualCurrentDeviceType.find_or_create_by!(name: "A")
    rcd_type_ac = ResidualCurrentDeviceType.find_or_create_by!(name: "AC")

    test_dwelling = Dwelling.create!(name: "Test Dwelling With Type A")
    test_panel = ElectricalPanel.create!(name: "With Type A Panel", dwelling: test_dwelling, room: room, input_cable: cable_6)
    ResidualCurrentDevice.create!(electrical_panel: test_panel, output_max_current: 40, residual_current_device_type: rcd_type_a, row_number: 1, position: 1)
    ResidualCurrentDevice.create!(electrical_panel: test_panel, output_max_current: 40, residual_current_device_type: rcd_type_ac, row_number: 1, position: 2)

    violations = engine.check_dwelling(test_dwelling)
    violations.none? { |v| v.rule_code.to_s == "min_rcd_type_a" }
  end

  # TEST 15: EV charger must be on RCD type A or F
  total_tests += 1
  passed_tests += 1 if test("ev_charger_rcd_type rule - should detect wrong RCD type") do
    rcd_type_ac = ResidualCurrentDeviceType.find_or_create_by!(name: "AC")
    ev_charger_type = ItemType.find_or_create_by!(name: "ev charger")

    test_dwelling = Dwelling.create!(name: "Test EV Charger Dwelling")
    test_panel = ElectricalPanel.create!(name: "EV Panel", dwelling: test_dwelling, room: room, input_cable: cable_6)
    test_rcd = ResidualCurrentDevice.create!(electrical_panel: test_panel, output_max_current: 40, residual_current_device_type: rcd_type_ac, row_number: 1, position: 1)
    test_breaker = Breaker.create!(residual_current_device: test_rcd, output_max_current: 20, position: 1)
    ev_charger = Item.create!(breaker: test_breaker, room: room, name: "EV Charger", item_type: ev_charger_type, input_cable: cable_2_5)

    violations = engine.check_resource(ev_charger)
    violations.any? { |v| v.rule_code.to_s == "ev_charger_rcd_type" }
  end

  # TEST 16: EV charger on RCD type A should pass
  total_tests += 1
  passed_tests += 1 if test("ev_charger_rcd_type rule - should pass with type A RCD") do
    rcd_type_a = ResidualCurrentDeviceType.find_or_create_by!(name: "A")
    ev_charger_type = ItemType.find_or_create_by!(name: "ev charger")

    test_dwelling = Dwelling.create!(name: "Test EV Charger A Dwelling")
    test_panel = ElectricalPanel.create!(name: "EV Panel A", dwelling: test_dwelling, room: room, input_cable: cable_6)
    test_rcd = ResidualCurrentDevice.create!(electrical_panel: test_panel, output_max_current: 40, residual_current_device_type: rcd_type_a, row_number: 1, position: 1)
    test_breaker = Breaker.create!(residual_current_device: test_rcd, output_max_current: 20, position: 1)
    ev_charger = Item.create!(breaker: test_breaker, room: room, name: "EV Charger", item_type: ev_charger_type, input_cable: cable_2_5)

    violations = engine.check_resource(ev_charger)
    violations.none? { |v| v.rule_code.to_s == "ev_charger_rcd_type" }
  end

  # TEST 17: EV charger on RCD type F should pass
  total_tests += 1
  passed_tests += 1 if test("ev_charger_rcd_type rule - should pass with type F RCD") do
    rcd_type_f = ResidualCurrentDeviceType.find_or_create_by!(name: "F")
    ev_charger_type = ItemType.find_or_create_by!(name: "ev charger")

    test_dwelling = Dwelling.create!(name: "Test EV Charger F Dwelling")
    test_panel = ElectricalPanel.create!(name: "EV Panel F", dwelling: test_dwelling, room: room, input_cable: cable_6)
    test_rcd = ResidualCurrentDevice.create!(electrical_panel: test_panel, output_max_current: 40, residual_current_device_type: rcd_type_f, row_number: 1, position: 1)
    test_breaker = Breaker.create!(residual_current_device: test_rcd, output_max_current: 20, position: 1)
    ev_charger = Item.create!(breaker: test_breaker, room: room, name: "EV Charger", item_type: ev_charger_type, input_cable: cable_2_5)

    violations = engine.check_resource(ev_charger)
    violations.none? { |v| v.rule_code.to_s == "ev_charger_rcd_type" }
  end

  # TEST 18: Shutter breaker with 16A should pass (cable validation skipped when no output_cable)
  # Note: Breaker model doesn't have output_cable relation, so cable validation returns true
  total_tests += 1
  passed_tests += 1 if test("shutter_current_cable_combo rule - should pass with 16A breaker") do
    shutter_type = ItemType.find_or_create_by!(name: "roller shutters")

    # Create a separate RCD for shutter tests to avoid position conflicts
    shutter_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 2, position: 1)
    test_breaker = Breaker.create!(residual_current_device: shutter_rcd, output_max_current: 16, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Shutter 1", item_type: shutter_type)

    violations = engine.check_resource(test_breaker)
    # Without output_cable, validation passes (returns true when cable is nil)
    violations.none? { |v| v.rule_code.to_s == "shutter_current_cable_combo" }
  end

  # TEST 19: Shutter breaker with 20A should pass (cable validation skipped when no output_cable)
  total_tests += 1
  passed_tests += 1 if test("shutter_current_cable_combo rule - should pass with 20A breaker") do
    shutter_type = ItemType.find_or_create_by!(name: "roller shutters")

    shutter_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 3, position: 1)
    test_breaker = Breaker.create!(residual_current_device: shutter_rcd, output_max_current: 20, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Shutter 2", item_type: shutter_type)

    violations = engine.check_resource(test_breaker)
    violations.none? { |v| v.rule_code.to_s == "shutter_current_cable_combo" }
  end

  # TEST 20: Shutter breaker with 25A should fail (exceeds max allowed current)
  total_tests += 1
  passed_tests += 1 if test("shutter_current_cable_combo rule - should fail with 25A breaker") do
    shutter_type = ItemType.find_or_create_by!(name: "roller shutters")

    shutter_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 4, position: 1)
    test_breaker = Breaker.create!(residual_current_device: shutter_rcd, output_max_current: 25, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Shutter 3", item_type: shutter_type)

    violations = engine.check_resource(test_breaker)
    violations.any? { |v| v.rule_code.to_s == "shutter_current_cable_combo" }
  end

  # TEST 21: Shutter breaker with 32A should fail (exceeds max allowed current)
  total_tests += 1
  passed_tests += 1 if test("shutter_current_cable_combo rule - should fail with 32A breaker") do
    shutter_type = ItemType.find_or_create_by!(name: "roller shutters")

    shutter_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 5, position: 1)
    test_breaker = Breaker.create!(residual_current_device: shutter_rcd, output_max_current: 32, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Shutter 4", item_type: shutter_type)

    violations = engine.check_resource(test_breaker)
    violations.any? { |v| v.rule_code.to_s == "shutter_current_cable_combo" }
  end

  # TEST 22: Convector 3000W with 16A should pass (within tier 1: ≤3500W → 16A)
  total_tests += 1
  passed_tests += 1 if test("convector_power_current_cable rule - 3000W/16A should pass") do
    conv_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 6, position: 1)
    test_breaker = Breaker.create!(residual_current_device: conv_rcd, output_max_current: 16, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Convector", item_type: convector_type, power_watts: 3000)

    violations = engine.check_resource(test_breaker)
    violations.none? { |v| v.rule_code.to_s == "convector_power_current_cable" }
  end

  # TEST 23: Convector 4000W with 20A should pass (within tier 2: ≤4500W → 20A)
  total_tests += 1
  passed_tests += 1 if test("convector_power_current_cable rule - 4000W/20A should pass") do
    conv_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 7, position: 1)
    test_breaker = Breaker.create!(residual_current_device: conv_rcd, output_max_current: 20, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Convector", item_type: convector_type, power_watts: 4000)

    violations = engine.check_resource(test_breaker)
    violations.none? { |v| v.rule_code.to_s == "convector_power_current_cable" }
  end

  # TEST 24: Convector 5000W with 25A should pass (within tier 3: ≤5750W → 25A)
  total_tests += 1
  passed_tests += 1 if test("convector_power_current_cable rule - 5000W/25A should pass") do
    conv_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 8, position: 1)
    test_breaker = Breaker.create!(residual_current_device: conv_rcd, output_max_current: 25, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Convector", item_type: convector_type, power_watts: 5000)

    violations = engine.check_resource(test_breaker)
    violations.none? { |v| v.rule_code.to_s == "convector_power_current_cable" }
  end

  # TEST 25: Convector 7000W with 32A should pass (within tier 4: ≤7250W → 32A)
  total_tests += 1
  passed_tests += 1 if test("convector_power_current_cable rule - 7000W/32A should pass") do
    conv_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 9, position: 1)
    test_breaker = Breaker.create!(residual_current_device: conv_rcd, output_max_current: 32, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Convector", item_type: convector_type, power_watts: 7000)

    violations = engine.check_resource(test_breaker)
    violations.none? { |v| v.rule_code.to_s == "convector_power_current_cable" }
  end

  # ========================================
  # EV CHARGER DEDICATED CIRCUIT TESTS
  # ========================================

  # TEST 26: EV charger with 20A breaker should pass
  total_tests += 1
  passed_tests += 1 if test("ev_charger_current_cable rule - 20A should pass") do
    ev_charger_type = ItemType.find_or_create_by!(name: "ev charger")
    ev_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 10, position: 1)
    test_breaker = Breaker.create!(residual_current_device: ev_rcd, output_max_current: 20, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "EV Charger", item_type: ev_charger_type)

    violations = engine.check_resource(test_breaker)
    violations.none? { |v| v.rule_code.to_s == "ev_charger_current_cable" }
  end

  # TEST 27: EV charger with 25A breaker should fail (must be 20A)
  total_tests += 1
  passed_tests += 1 if test("ev_charger_current_cable rule - 25A should fail") do
    ev_charger_type = ItemType.find_or_create_by!(name: "ev charger")
    ev_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 11, position: 1)
    test_breaker = Breaker.create!(residual_current_device: ev_rcd, output_max_current: 25, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "EV Charger", item_type: ev_charger_type)

    violations = engine.check_resource(test_breaker)
    violations.any? { |v| v.rule_code.to_s == "ev_charger_current_cable" }
  end

  # TEST 28: EV charger breaker with other items should fail (must be dedicated)
  total_tests += 1
  passed_tests += 1 if test("ev_charger_exclusive rule - mixed items should fail") do
    ev_charger_type = ItemType.find_or_create_by!(name: "ev charger")
    ev_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 12, position: 1)
    test_breaker = Breaker.create!(residual_current_device: ev_rcd, output_max_current: 20, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "EV Charger", item_type: ev_charger_type)
    Item.create!(breaker: test_breaker, room: room, name: "Socket", item_type: socket_type)

    violations = engine.check_resource(test_breaker)
    violations.any? { |v| v.rule_code.to_s == "ev_charger_exclusive" }
  end

  # ========================================
  # WATER HEATER DEDICATED CIRCUIT TESTS
  # ========================================

  # TEST 29: Water heater with 20A breaker should pass
  total_tests += 1
  passed_tests += 1 if test("water_heater_current_cable rule - 20A should pass") do
    water_heater_type = ItemType.find_or_create_by!(name: "water heater")
    wh_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 13, position: 1)
    test_breaker = Breaker.create!(residual_current_device: wh_rcd, output_max_current: 20, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Water Heater", item_type: water_heater_type, power_watts: 2000)

    violations = engine.check_resource(test_breaker)
    violations.none? { |v| v.rule_code.to_s == "water_heater_current_cable" }
  end

  # TEST 30: Water heater with 25A breaker should fail (must be 20A)
  total_tests += 1
  passed_tests += 1 if test("water_heater_current_cable rule - 25A should fail") do
    water_heater_type = ItemType.find_or_create_by!(name: "water heater")
    wh_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 14, position: 1)
    test_breaker = Breaker.create!(residual_current_device: wh_rcd, output_max_current: 25, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Water Heater", item_type: water_heater_type, power_watts: 2000)

    violations = engine.check_resource(test_breaker)
    violations.any? { |v| v.rule_code.to_s == "water_heater_current_cable" }
  end

  # TEST 31: Water heater breaker with other items should fail (must be dedicated)
  total_tests += 1
  passed_tests += 1 if test("water_heater_exclusive rule - mixed items should fail") do
    water_heater_type = ItemType.find_or_create_by!(name: "water heater")
    wh_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 15, position: 1)
    test_breaker = Breaker.create!(residual_current_device: wh_rcd, output_max_current: 20, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Water Heater", item_type: water_heater_type, power_watts: 2000)
    Item.create!(breaker: test_breaker, room: room, name: "Socket", item_type: socket_type)

    violations = engine.check_resource(test_breaker)
    violations.any? { |v| v.rule_code.to_s == "water_heater_exclusive" }
  end

  # ========================================
  # FREEZER DEDICATED CIRCUIT TESTS
  # ========================================

  # TEST 32: Freezer with 16A breaker should pass
  total_tests += 1
  passed_tests += 1 if test("freezer_current_cable rule - 16A should pass") do
    freezer_type = ItemType.find_or_create_by!(name: "freezer")
    freezer_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 16, position: 1)
    test_breaker = Breaker.create!(residual_current_device: freezer_rcd, output_max_current: 16, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Freezer", item_type: freezer_type)

    violations = engine.check_resource(test_breaker)
    violations.none? { |v| v.rule_code.to_s == "freezer_current_cable" }
  end

  # TEST 33: Freezer with 20A breaker should fail (must be 16A)
  total_tests += 1
  passed_tests += 1 if test("freezer_current_cable rule - 20A should fail") do
    freezer_type = ItemType.find_or_create_by!(name: "freezer")
    freezer_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 17, position: 1)
    test_breaker = Breaker.create!(residual_current_device: freezer_rcd, output_max_current: 20, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Freezer", item_type: freezer_type)

    violations = engine.check_resource(test_breaker)
    violations.any? { |v| v.rule_code.to_s == "freezer_current_cable" }
  end

  # TEST 34: Freezer breaker with other items should trigger warning (dedicated recommended)
  total_tests += 1
  passed_tests += 1 if test("freezer_exclusive rule - mixed items should warn") do
    freezer_type = ItemType.find_or_create_by!(name: "freezer")
    freezer_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 18, position: 1)
    test_breaker = Breaker.create!(residual_current_device: freezer_rcd, output_max_current: 16, position: 1)
    Item.create!(breaker: test_breaker, room: room, name: "Freezer", item_type: freezer_type)
    Item.create!(breaker: test_breaker, room: room, name: "Socket", item_type: socket_type)

    violations = engine.check_resource(test_breaker)
    violations.any? { |v| v.rule_code.to_s == "freezer_exclusive" }
  end

  # ========================================
  # SHUTTER MAX COUNT TESTS
  # ========================================

  # TEST 35: Shutter breaker with 8 shutters should pass
  total_tests += 1
  passed_tests += 1 if test("shutter_max_count rule - 8 shutters should pass") do
    shutter_type = ItemType.find_or_create_by!(name: "roller shutters")
    shutter_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 19, position: 1)
    test_breaker = Breaker.create!(residual_current_device: shutter_rcd, output_max_current: 16, position: 1)
    8.times { |i| Item.create!(breaker: test_breaker, room: room, name: "Shutter #{i+1}", item_type: shutter_type) }

    violations = engine.check_resource(test_breaker)
    violations.none? { |v| v.rule_code.to_s == "shutter_max_count" }
  end

  # TEST 36: Shutter breaker with 9 shutters should fail
  total_tests += 1
  passed_tests += 1 if test("shutter_max_count rule - 9 shutters should fail") do
    shutter_type = ItemType.find_or_create_by!(name: "roller shutters")
    shutter_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 20, position: 1)
    test_breaker = Breaker.create!(residual_current_device: shutter_rcd, output_max_current: 16, position: 1)
    9.times { |i| Item.create!(breaker: test_breaker, room: room, name: "Shutter #{i+1}", item_type: shutter_type) }

    violations = engine.check_resource(test_breaker)
    violations.any? { |v| v.rule_code.to_s == "shutter_max_count" }
  end

  # ========================================
  # MINIMUM SOCKET COUNTS PER ROOM TYPE TESTS
  # ========================================

  # TEST 37: Living room with 5 sockets should pass (minimum for living room)
  total_tests += 1
  passed_tests += 1 if test("living_room_min_sockets rule - 5 sockets should pass") do
    living_room = Room.create!(name: "Living Room", floor: floor, room_type: "living_room", surface_area: 20)
    living_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 21, position: 1)
    test_breaker = Breaker.create!(residual_current_device: living_rcd, output_max_current: 16, position: 1)
    5.times { |i| Item.create!(breaker: test_breaker, room: living_room, name: "Socket #{i+1}", item_type: socket_type) }

    violations = engine.check_resource(living_room)
    violations.none? { |v| v.rule_code.to_s == "living_room_min_sockets" }
  end

  # TEST 38: Living room with 3 sockets should fail (minimum 5 required)
  total_tests += 1
  passed_tests += 1 if test("living_room_min_sockets rule - 3 sockets should fail") do
    living_room = Room.create!(name: "Living Room 2", floor: floor, room_type: "living_room", surface_area: 20)
    living_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 22, position: 1)
    test_breaker = Breaker.create!(residual_current_device: living_rcd, output_max_current: 16, position: 1)
    3.times { |i| Item.create!(breaker: test_breaker, room: living_room, name: "Socket #{i+1}", item_type: socket_type) }

    violations = engine.check_resource(living_room)
    violations.any? { |v| v.rule_code.to_s == "living_room_min_sockets" }
  end

  # TEST 39: Large living room (40m²) should require 10 sockets (1 per 4m²)
  total_tests += 1
  passed_tests += 1 if test("living_room_min_sockets rule - 40m² needs 10 sockets") do
    large_living = Room.create!(name: "Large Living", floor: floor, room_type: "living_room", surface_area: 40)
    large_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 23, position: 1)
    test_breaker = Breaker.create!(residual_current_device: large_rcd, output_max_current: 16, position: 1)
    9.times { |i| Item.create!(breaker: test_breaker, room: large_living, name: "Socket #{i+1}", item_type: socket_type) }

    violations = engine.check_resource(large_living)
    # 9 sockets for 40m² should fail (needs 10)
    violations.any? { |v| v.rule_code.to_s == "living_room_min_sockets" }
  end

  # TEST 40: Bedroom with 3 sockets should pass
  total_tests += 1
  passed_tests += 1 if test("bedroom_min_sockets rule - 3 sockets should pass") do
    bedroom = Room.create!(name: "Bedroom 1", floor: floor, room_type: "bedroom", surface_area: 12)
    bed_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 24, position: 1)
    test_breaker = Breaker.create!(residual_current_device: bed_rcd, output_max_current: 16, position: 1)
    3.times { |i| Item.create!(breaker: test_breaker, room: bedroom, name: "Socket #{i+1}", item_type: socket_type) }

    violations = engine.check_resource(bedroom)
    violations.none? { |v| v.rule_code.to_s == "bedroom_min_sockets" }
  end

  # TEST 41: Bedroom with 2 sockets should fail
  total_tests += 1
  passed_tests += 1 if test("bedroom_min_sockets rule - 2 sockets should fail") do
    bedroom = Room.create!(name: "Bedroom 2", floor: floor, room_type: "bedroom", surface_area: 12)
    bed_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 25, position: 1)
    test_breaker = Breaker.create!(residual_current_device: bed_rcd, output_max_current: 16, position: 1)
    2.times { |i| Item.create!(breaker: test_breaker, room: bedroom, name: "Socket #{i+1}", item_type: socket_type) }

    violations = engine.check_resource(bedroom)
    violations.any? { |v| v.rule_code.to_s == "bedroom_min_sockets" }
  end

  # TEST 42: Kitchen with 6 sockets should pass
  total_tests += 1
  passed_tests += 1 if test("kitchen_min_sockets rule - 6 sockets should pass") do
    test_kitchen = Room.create!(name: "Test Kitchen", floor: floor, room_type: "kitchen", surface_area: 15, is_kitchen: true)
    kit_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 26, position: 1)
    test_breaker = Breaker.create!(residual_current_device: kit_rcd, output_max_current: 20, position: 1)
    6.times { |i| Item.create!(breaker: test_breaker, room: test_kitchen, name: "Socket #{i+1}", item_type: socket_type) }

    violations = engine.check_resource(test_kitchen)
    violations.none? { |v| v.rule_code.to_s == "kitchen_min_sockets" }
  end

  # TEST 43: Kitchen with 4 sockets should fail
  total_tests += 1
  passed_tests += 1 if test("kitchen_min_sockets rule - 4 sockets should fail") do
    test_kitchen = Room.create!(name: "Small Kitchen", floor: floor, room_type: "kitchen", surface_area: 10, is_kitchen: true)
    kit_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 27, position: 1)
    test_breaker = Breaker.create!(residual_current_device: kit_rcd, output_max_current: 20, position: 1)
    4.times { |i| Item.create!(breaker: test_breaker, room: test_kitchen, name: "Socket #{i+1}", item_type: socket_type) }

    violations = engine.check_resource(test_kitchen)
    violations.any? { |v| v.rule_code.to_s == "kitchen_min_sockets" }
  end

  # TEST 44: Other room > 4m² with 1 socket should pass
  total_tests += 1
  passed_tests += 1 if test("other_room_min_sockets rule - 1 socket should pass") do
    hallway = Room.create!(name: "Hallway", floor: floor, room_type: "other", surface_area: 8)
    hall_rcd = ResidualCurrentDevice.create!(electrical_panel: panel, output_max_current: 40, residual_current_device_type: rcd_type, row_number: 28, position: 1)
    test_breaker = Breaker.create!(residual_current_device: hall_rcd, output_max_current: 16, position: 1)
    Item.create!(breaker: test_breaker, room: hallway, name: "Socket 1", item_type: socket_type)

    violations = engine.check_resource(hallway)
    violations.none? { |v| v.rule_code.to_s == "other_room_min_sockets" }
  end

  # TEST 45: Other room > 4m² with 0 sockets should fail
  total_tests += 1
  passed_tests += 1 if test("other_room_min_sockets rule - 0 sockets should fail") do
    hallway = Room.create!(name: "Hallway 2", floor: floor, room_type: "other", surface_area: 8)

    violations = engine.check_resource(hallway)
    violations.any? { |v| v.rule_code.to_s == "other_room_min_sockets" }
  end

  raise ActiveRecord::Rollback # Rollback all test data
end

# Print summary
puts "\n"
puts "=" * 80
puts "TEST SUMMARY"
puts "=" * 80
puts "Total tests:  #{total_tests}"
puts "Passed:       #{passed_tests} ✓"
puts "Failed:       #{total_tests - passed_tests} ✗"
puts "Success rate: #{(passed_tests.to_f / total_tests * 100).round(1)}%"
puts "=" * 80

if passed_tests == total_tests
  puts "\n✓ ALL TESTS PASSED"
  exit 0
else
  puts "\n✗ SOME TESTS FAILED"
  exit 1
end
