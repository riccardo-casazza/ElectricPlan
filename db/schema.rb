# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_12_185112) do
  create_table "breakers", force: :cascade do |t|
    t.integer "residual_current_device_id", null: false
    t.integer "position"
    t.integer "output_max_current"
    t.text "description"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["residual_current_device_id"], name: "index_breakers_on_residual_current_device_id"
  end

  create_table "cables", force: :cascade do |t|
    t.string "section"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "electrical_panels", force: :cascade do |t|
    t.string "name"
    t.integer "room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "input_cable_id"
    t.index ["input_cable_id"], name: "index_electrical_panels_on_input_cable_id"
    t.index ["room_id"], name: "index_electrical_panels_on_room_id"
  end

  create_table "floors", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "items", force: :cascade do |t|
    t.integer "breaker_id", null: false
    t.integer "room_id", null: false
    t.string "name"
    t.integer "item_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "input_cable_id"
    t.index ["breaker_id"], name: "index_items_on_breaker_id"
    t.index ["input_cable_id"], name: "index_items_on_input_cable_id"
    t.index ["item_type_id"], name: "index_items_on_item_type_id"
    t.index ["room_id"], name: "index_items_on_room_id"
  end

  create_table "residual_current_device_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "residual_current_devices", force: :cascade do |t|
    t.integer "electrical_panel_id", null: false
    t.integer "row_number"
    t.integer "position"
    t.integer "output_max_current"
    t.integer "residual_current_device_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["electrical_panel_id"], name: "index_residual_current_devices_on_electrical_panel_id"
    t.index ["residual_current_device_type_id"], name: "idx_on_residual_current_device_type_id_c2494ae394"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.integer "floor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["floor_id"], name: "index_rooms_on_floor_id"
  end

  create_table "rule_violations", force: :cascade do |t|
    t.integer "rule_id", null: false
    t.string "resource_type"
    t.integer "resource_id"
    t.string "severity"
    t.text "message"
    t.json "context"
    t.boolean "resolved", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_type", "resource_id"], name: "index_rule_violations_on_resource_type_and_resource_id"
    t.index ["rule_id"], name: "index_rule_violations_on_rule_id"
  end

  create_table "rules", force: :cascade do |t|
    t.text "description"
    t.text "rule"
    t.string "applies_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "breakers", "residual_current_devices"
  add_foreign_key "electrical_panels", "cables", column: "input_cable_id"
  add_foreign_key "items", "breakers"
  add_foreign_key "items", "cables", column: "input_cable_id"
  add_foreign_key "items", "item_types"
  add_foreign_key "items", "rooms"
  add_foreign_key "residual_current_devices", "electrical_panels"
  add_foreign_key "residual_current_devices", "residual_current_device_types"
  add_foreign_key "rooms", "floors"
  add_foreign_key "rule_violations", "rules"
end
