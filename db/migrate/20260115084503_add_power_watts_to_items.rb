class AddPowerWattsToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :power_watts, :integer
  end
end
