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

  # TEST 5: Convector breaker exceeding max current (should fail)
  total_tests += 1
  passed_tests += 1 if test("convector_max_current rule - should detect >20A") do
    breaker = Breaker.create!(residual_current_device: rcd, output_max_current: 25, position: 5)
    Item.create!(breaker: breaker, room: room, name: "Convector 1", item_type: convector_type, power_watts: 2000, input_cable: cable_2_5)

    violations = engine.check_resource(breaker)
    violations.any? { |v| v.rule_code.to_s == "convector_max_current" }
  end

  # TEST 6: Convector breaker exceeding 4500W (should fail)
  total_tests += 1
  passed_tests += 1 if test("convector_max_power rule - should detect >4500W") do
    breaker = Breaker.create!(residual_current_device: rcd, output_max_current: 20, position: 6)
    Item.create!(breaker: breaker, room: room, name: "Convector 1", item_type: convector_type, power_watts: 2500, input_cable: cable_2_5)
    Item.create!(breaker: breaker, room: room, name: "Convector 2", item_type: convector_type, power_watts: 2500, input_cable: cable_2_5)

    violations = engine.check_resource(breaker)
    violations.any? { |v| v.rule_code.to_s == "convector_max_power" }
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
