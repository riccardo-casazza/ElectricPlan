class AddNameToResidualCurrentDevices < ActiveRecord::Migration[8.0]
  def change
    add_column :residual_current_devices, :name, :string
  end
end
