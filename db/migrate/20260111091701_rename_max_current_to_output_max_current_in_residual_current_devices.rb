class RenameMaxCurrentToOutputMaxCurrentInResidualCurrentDevices < ActiveRecord::Migration[8.0]
  def change
    rename_column :residual_current_devices, :max_current, :output_max_current
  end
end
