class FixForeignKeyTypesForMysql < ActiveRecord::Migration[8.0]
  def up
    # Remove foreign keys first
    remove_foreign_key :breakers, :residual_current_devices
    remove_foreign_key :electrical_panels, :cables
    remove_foreign_key :items, :breakers
    remove_foreign_key :items, :cables
    remove_foreign_key :items, :item_types
    remove_foreign_key :items, :rooms
    remove_foreign_key :residual_current_devices, :electrical_panels
    remove_foreign_key :residual_current_devices, :residual_current_device_types
    remove_foreign_key :rooms, :floors
    remove_foreign_key :rule_violations, :rules

    # Change foreign key columns from integer to bigint
    change_column :breakers, :residual_current_device_id, :bigint, null: false
    change_column :electrical_panels, :room_id, :bigint, null: false
    change_column :electrical_panels, :input_cable_id, :bigint
    change_column :items, :breaker_id, :bigint, null: false
    change_column :items, :room_id, :bigint, null: false
    change_column :items, :item_type_id, :bigint, null: false
    change_column :items, :input_cable_id, :bigint
    change_column :residual_current_devices, :electrical_panel_id, :bigint, null: false
    change_column :residual_current_devices, :residual_current_device_type_id, :bigint, null: false
    change_column :rooms, :floor_id, :bigint, null: false
    change_column :rule_violations, :rule_id, :bigint, null: false
    change_column :rule_violations, :resource_id, :bigint

    # Re-add foreign keys
    add_foreign_key :breakers, :residual_current_devices
    add_foreign_key :electrical_panels, :cables, column: :input_cable_id
    add_foreign_key :items, :breakers
    add_foreign_key :items, :cables, column: :input_cable_id
    add_foreign_key :items, :item_types
    add_foreign_key :items, :rooms
    add_foreign_key :residual_current_devices, :electrical_panels
    add_foreign_key :residual_current_devices, :residual_current_device_types
    add_foreign_key :rooms, :floors
    add_foreign_key :rule_violations, :rules
  end

  def down
    # Remove foreign keys
    remove_foreign_key :breakers, :residual_current_devices
    remove_foreign_key :electrical_panels, :cables
    remove_foreign_key :items, :breakers
    remove_foreign_key :items, :cables
    remove_foreign_key :items, :item_types
    remove_foreign_key :items, :rooms
    remove_foreign_key :residual_current_devices, :electrical_panels
    remove_foreign_key :residual_current_devices, :residual_current_device_types
    remove_foreign_key :rooms, :floors
    remove_foreign_key :rule_violations, :rules

    # Change back to integer
    change_column :breakers, :residual_current_device_id, :integer, null: false
    change_column :electrical_panels, :room_id, :integer, null: false
    change_column :electrical_panels, :input_cable_id, :integer
    change_column :items, :breaker_id, :integer, null: false
    change_column :items, :room_id, :integer, null: false
    change_column :items, :item_type_id, :integer, null: false
    change_column :items, :input_cable_id, :integer
    change_column :residual_current_devices, :electrical_panel_id, :integer, null: false
    change_column :residual_current_devices, :residual_current_device_type_id, :integer, null: false
    change_column :rooms, :floor_id, :integer, null: false
    change_column :rule_violations, :rule_id, :integer, null: false
    change_column :rule_violations, :resource_id, :integer

    # Re-add foreign keys
    add_foreign_key :breakers, :residual_current_devices
    add_foreign_key :electrical_panels, :cables, column: :input_cable_id
    add_foreign_key :items, :breakers
    add_foreign_key :items, :cables, column: :input_cable_id
    add_foreign_key :items, :item_types
    add_foreign_key :items, :rooms
    add_foreign_key :residual_current_devices, :electrical_panels
    add_foreign_key :residual_current_devices, :residual_current_device_types
    add_foreign_key :rooms, :floors
    add_foreign_key :rule_violations, :rules
  end
end
