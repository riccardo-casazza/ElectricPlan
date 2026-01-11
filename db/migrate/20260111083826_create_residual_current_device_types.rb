class CreateResidualCurrentDeviceTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :residual_current_device_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
