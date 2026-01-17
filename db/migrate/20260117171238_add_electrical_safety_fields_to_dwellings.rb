class AddElectricalSafetyFieldsToDwellings < ActiveRecord::Migration[8.0]
  def change
    add_column :dwellings, :has_lightning_protection, :boolean, default: false
    add_column :dwellings, :has_overhead_power_line, :boolean, default: false
    add_column :dwellings, :has_safety_critical_persons, :boolean, default: false
    add_column :dwellings, :has_sensitive_equipment, :boolean, default: false
  end
end
