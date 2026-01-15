require "test_helper"

class ComplianceEngineTest < ActiveSupport::TestCase
  def setup
    @engine = ComplianceEngine.new

    # Create test data
    @floor = Floor.create!(name: "Ground Floor")
    @room = Room.create!(name: "Living Room", floor: @floor)
    @kitchen = Room.create!(name: "Kitchen", floor: @floor, is_kitchen: true)
    @laundry = Room.create!(name: "Laundry", floor: @floor)

    @cable_1_5 = Cable.find_or_create_by!(section: 1.5)
    @cable_2_5 = Cable.find_or_create_by!(section: 2.5)
    @cable_6 = Cable.find_or_create_by!(section: 6)

    @dwelling = Dwelling.create!(name: "Test House")
    @panel = ElectricalPanel.create!(name: "Main", dwelling: @dwelling, room: @room, input_cable: @cable_6)
    @rcd = ResidualCurrentDevice.create!(
      electrical_panel: @panel,
      output_max_current: 40,
      residual_current_device_type: ResidualCurrentDeviceType.first || ResidualCurrentDeviceType.create!(name: "Type A")
    )

    @light_type = ItemType.find_or_create_by!(name: "light")
    @socket_type = ItemType.find_or_create_by!(name: "socket")
    @convector_type = ItemType.find_or_create_by!(name: "convector")
    @dishwasher_type = ItemType.find_or_create_by!(name: "dishwasher")
    @oven_type = ItemType.find_or_create_by!(name: "oven")
    @cooktop_type = ItemType.find_or_create_by!(name: "cooktop")
    @shutter_type = ItemType.find_or_create_by!(name: "roller shutters")
  end

  # ========================================
  # BREAKER RULES - LIGHTS
  # ========================================

  test "light_only: should fail when breaker has non-light items" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 16,
      output_cable: @cable_1_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Light 1", item_type: @light_type)
    Item.create!(breaker: breaker, room: @room, name: "Socket 1", item_type: @socket_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "light_only" }, "Should detect non-light items in light breaker"
  end

  test "light_only: should pass when breaker has only lights" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 16,
      output_cable: @cable_1_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Light 1", item_type: @light_type)
    Item.create!(breaker: breaker, room: @room, name: "Light 2", item_type: @light_type)

    violations = @engine.check_resource(breaker)
    assert violations.none? { |v| v.rule_code.to_s == "light_only" }
  end

  test "light_max_count: should fail when breaker has more than 8 lights" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 16,
      output_cable: @cable_1_5
    )
    9.times do |i|
      Item.create!(breaker: breaker, room: @room, name: "Light #{i+1}", item_type: @light_type)
    end

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "light_max_count" }
  end

  test "light_max_current: should fail when light breaker exceeds 16A" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_1_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Light 1", item_type: @light_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "light_max_current" }
  end

  test "light_min_cable: should fail when light breaker has insufficient cable" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 16,
      output_cable: Cable.create!(section: 1.0)
    )
    Item.create!(breaker: breaker, room: @room, name: "Light 1", item_type: @light_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "light_min_cable" }
  end

  # ========================================
  # BREAKER RULES - SOCKETS (16A)
  # ========================================

  test "socket_16a_only: should fail when 16A socket breaker has non-sockets" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 16,
      output_cable: @cable_1_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Socket 1", item_type: @socket_type)
    Item.create!(breaker: breaker, room: @room, name: "Light 1", item_type: @light_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "socket_16a_only" }
  end

  test "socket_16a_max_count: should fail when 16A socket breaker has more than 5 sockets" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 16,
      output_cable: @cable_1_5
    )
    6.times do |i|
      Item.create!(breaker: breaker, room: @room, name: "Socket #{i+1}", item_type: @socket_type)
    end

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "socket_16a_max_count" }
  end

  test "socket_16a_min_cable: should fail when 16A socket breaker has insufficient cable" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 16,
      output_cable: Cable.create!(section: 1.0)
    )
    Item.create!(breaker: breaker, room: @room, name: "Socket 1", item_type: @socket_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "socket_16a_min_cable" }
  end

  # ========================================
  # BREAKER RULES - SOCKETS (20A)
  # ========================================

  test "socket_20a_only: should fail when 20A socket breaker has non-sockets" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_2_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Socket 1", item_type: @socket_type)
    Item.create!(breaker: breaker, room: @room, name: "Light 1", item_type: @light_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "socket_20a_only" }
  end

  test "socket_20a_max_count: should fail when 20A socket breaker has more than 8 sockets" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_2_5
    )
    9.times do |i|
      Item.create!(breaker: breaker, room: @room, name: "Socket #{i+1}", item_type: @socket_type)
    end

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "socket_20a_max_count" }
  end

  test "socket_20a_min_cable: should fail when 20A socket breaker has insufficient cable" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_1_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Socket 1", item_type: @socket_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "socket_20a_min_cable" }
  end

  # ========================================
  # BREAKER RULES - KITCHEN SOCKETS
  # ========================================

  test "kitchen_socket_exclusive: should fail when kitchen socket breaker has non-kitchen items" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_2_5
    )
    Item.create!(breaker: breaker, room: @kitchen, name: "Socket 1", item_type: @socket_type)
    Item.create!(breaker: breaker, room: @room, name: "Socket 2", item_type: @socket_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "kitchen_socket_exclusive" }
  end

  test "kitchen_socket_max_current: should fail when kitchen socket breaker exceeds 20A" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 25,
      output_cable: @cable_2_5
    )
    Item.create!(breaker: breaker, room: @kitchen, name: "Socket 1", item_type: @socket_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "kitchen_socket_max_current" }
  end

  test "kitchen_socket_min_cable: should fail when kitchen socket breaker has insufficient cable" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_1_5
    )
    Item.create!(breaker: breaker, room: @kitchen, name: "Socket 1", item_type: @socket_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "kitchen_socket_min_cable" }
  end

  test "kitchen_socket_max_count: should fail when kitchen socket breaker has more than 6 sockets" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_2_5
    )
    7.times do |i|
      Item.create!(breaker: breaker, room: @kitchen, name: "Socket #{i+1}", item_type: @socket_type)
    end

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "kitchen_socket_max_count" }
  end

  # ========================================
  # BREAKER RULES - SHUTTERS
  # ========================================

  test "shutter_exclusive: should fail when shutter breaker has non-shutters" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 16,
      output_cable: @cable_1_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Shutter 1", item_type: @shutter_type)
    Item.create!(breaker: breaker, room: @room, name: "Light 1", item_type: @light_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "shutter_exclusive" }
  end

  test "shutter_max_current: should fail when shutter breaker exceeds 16A" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_1_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Shutter 1", item_type: @shutter_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "shutter_max_current" }
  end

  test "shutter_min_cable: should fail when shutter breaker has insufficient cable" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 16,
      output_cable: Cable.create!(section: 1.0)
    )
    Item.create!(breaker: breaker, room: @room, name: "Shutter 1", item_type: @shutter_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "shutter_min_cable" }
  end

  # ========================================
  # BREAKER RULES - CONVECTORS
  # ========================================

  test "convector_exclusive: should fail when convector breaker has non-convectors" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_2_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Convector 1", item_type: @convector_type, power_watts: 2000)
    Item.create!(breaker: breaker, room: @room, name: "Light 1", item_type: @light_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "convector_exclusive" }
  end

  test "convector_max_power: should fail when convector breaker exceeds 4500W" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_2_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Convector 1", item_type: @convector_type, power_watts: 2500)
    Item.create!(breaker: breaker, room: @room, name: "Convector 2", item_type: @convector_type, power_watts: 2500)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "convector_max_power" }
  end

  test "convector_max_current: should fail when convector breaker exceeds 20A" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 25,
      output_cable: @cable_2_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Convector 1", item_type: @convector_type, power_watts: 2000)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "convector_max_current" }
  end

  test "convector_min_cable: should fail when convector breaker has insufficient cable" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_1_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Convector 1", item_type: @convector_type, power_watts: 2000)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "convector_min_cable" }
  end

  # ========================================
  # BREAKER RULES - APPLIANCES
  # ========================================

  test "appliance_exclusive: should fail when appliance breaker has multiple appliances" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_2_5
    )
    Item.create!(breaker: breaker, room: @kitchen, name: "Dishwasher", item_type: @dishwasher_type)
    Item.create!(breaker: breaker, room: @kitchen, name: "Oven", item_type: @oven_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "appliance_exclusive" }
  end

  test "appliance_max_current: should fail when appliance breaker exceeds 20A" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 25,
      output_cable: @cable_2_5
    )
    Item.create!(breaker: breaker, room: @kitchen, name: "Dishwasher", item_type: @dishwasher_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "appliance_max_current" }
  end

  test "appliance_min_cable: should fail when appliance breaker has insufficient cable" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_1_5
    )
    Item.create!(breaker: breaker, room: @kitchen, name: "Dishwasher", item_type: @dishwasher_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "appliance_min_cable" }
  end

  # ========================================
  # BREAKER RULES - COOKTOP
  # ========================================

  test "cooktop_exclusive: should fail when cooktop breaker has other items" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 32,
      output_cable: @cable_6
    )
    Item.create!(breaker: breaker, room: @kitchen, name: "Cooktop", item_type: @cooktop_type)
    Item.create!(breaker: breaker, room: @kitchen, name: "Oven", item_type: @oven_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "cooktop_exclusive" }
  end

  test "cooktop_max_current: should fail when cooktop breaker exceeds 32A" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 40,
      output_cable: @cable_6
    )
    Item.create!(breaker: breaker, room: @kitchen, name: "Cooktop", item_type: @cooktop_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "cooktop_max_current" }
  end

  test "cooktop_min_cable: should fail when cooktop breaker has insufficient cable" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 32,
      output_cable: @cable_2_5
    )
    Item.create!(breaker: breaker, room: @kitchen, name: "Cooktop", item_type: @cooktop_type)

    violations = @engine.check_resource(breaker)
    assert violations.any? { |v| v.rule_code.to_s == "cooktop_min_cable" }
  end

  # ========================================
  # ITEM RULES
  # ========================================

  test "oven_location: should fail when oven is not in kitchen/laundry" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_2_5
    )
    item = Item.create!(breaker: breaker, room: @room, name: "Oven", item_type: @oven_type)

    violations = @engine.check_resource(item)
    assert violations.any? { |v| v.rule_code.to_s == "oven_location" }
  end

  test "dishwasher_location: should fail when dishwasher is not in kitchen/laundry" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_2_5
    )
    item = Item.create!(breaker: breaker, room: @room, name: "Dishwasher", item_type: @dishwasher_type)

    violations = @engine.check_resource(item)
    assert violations.any? { |v| v.rule_code.to_s == "dishwasher_location" }
  end

  test "washing_machine_location: should pass when in laundry" do
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_2_5
    )
    washing_machine_type = ItemType.find_or_create_by!(name: "washing machine")
    item = Item.create!(breaker: breaker, room: @laundry, name: "Washing Machine", item_type: washing_machine_type)

    violations = @engine.check_resource(item)
    assert violations.none? { |v| v.rule_code.to_s == "washing_machine_location" }
  end

  # ========================================
  # RCD RULES
  # ========================================

  test "rcd_sufficient_current: should fail when RCD current is insufficient for load" do
    rcd = ResidualCurrentDevice.create!(
      electrical_panel: @panel,
      output_max_current: 20,
      residual_current_device_type: ResidualCurrentDeviceType.first
    )
    breaker = Breaker.create!(
      residual_current_device: rcd,
      output_max_current: 16,
      output_cable: @cable_1_5
    )

    # Stub total_breaker_current to return value exceeding RCD capacity
    rcd.define_singleton_method(:total_breaker_current) { 25 }

    violations = @engine.check_resource(rcd)
    assert violations.any? { |v| v.rule_code.to_s == "rcd_sufficient_current" }
  end

  # ========================================
  # SYSTEM RULES
  # ========================================

  test "min_light_breakers: should detect insufficient light breakers" do
    # Clear existing breakers
    Breaker.destroy_all

    # Create only 1 light breaker (minimum is 2)
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 16,
      output_cable: @cable_1_5
    )
    Item.create!(breaker: breaker, room: @room, name: "Light 1", item_type: @light_type)

    violations = @engine.check_system
    assert violations.any? { |v| v.rule_code.to_s == "min_light_circuits" }
  end

  test "min_shutter_breakers: should detect missing shutter breaker" do
    # Clear existing breakers
    Breaker.destroy_all

    violations = @engine.check_system
    assert violations.any? { |v| v.rule_code.to_s == "min_shutter_circuits" }
  end

  test "min_appliance_circuits: should detect insufficient appliance breakers" do
    # Clear existing breakers
    Breaker.destroy_all

    # Create only 1 appliance breaker (minimum is 3)
    breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 20,
      output_cable: @cable_2_5
    )
    Item.create!(breaker: breaker, room: @kitchen, name: "Dishwasher", item_type: @dishwasher_type)

    violations = @engine.check_system
    assert violations.any? { |v| v.rule_code.to_s == "min_appliance_circuits" }
  end

  test "system rules: should pass when all minimum circuits are present" do
    # Clear existing breakers
    Breaker.destroy_all

    # Create 2 light breakers
    2.times do |i|
      breaker = Breaker.create!(
        residual_current_device: @rcd,
        output_max_current: 16,
        output_cable: @cable_1_5
      )
      Item.create!(breaker: breaker, room: @room, name: "Light #{i+1}", item_type: @light_type)
    end

    # Create 1 shutter breaker
    shutter_breaker = Breaker.create!(
      residual_current_device: @rcd,
      output_max_current: 16,
      output_cable: @cable_1_5
    )
    Item.create!(breaker: shutter_breaker, room: @room, name: "Shutter 1", item_type: @shutter_type)

    # Create 3 appliance breakers
    [
      [ @dishwasher_type, "Dishwasher" ],
      [ @oven_type, "Oven" ],
      [ ItemType.find_or_create_by!(name: "washing machine"), "Washing Machine" ]
    ].each do |type, name|
      breaker = Breaker.create!(
        residual_current_device: @rcd,
        output_max_current: 20,
        output_cable: @cable_2_5
      )
      room_to_use = name == "Washing Machine" ? @laundry : @kitchen
      Item.create!(breaker: breaker, room: room_to_use, name: name, item_type: type)
    end

    violations = @engine.check_system
    system_violations = violations.select { |v| [ "min_light_circuits", "min_shutter_circuits", "min_appliance_circuits" ].include?(v.rule_code.to_s) }
    assert system_violations.empty?, "Should pass all system rules when minimum circuits are present"
  end
end
