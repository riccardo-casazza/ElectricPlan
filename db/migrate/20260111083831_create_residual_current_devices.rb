class CreateResidualCurrentDevices < ActiveRecord::Migration[8.0]
  def change
    create_table :residual_current_devices do |t|
      t.references :electrical_panel, null: false, foreign_key: true
      t.integer :row_number
      t.integer :position
      t.integer :max_current
      t.references :residual_current_device_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
