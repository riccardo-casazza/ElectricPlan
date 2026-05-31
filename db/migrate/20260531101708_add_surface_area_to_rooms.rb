class AddSurfaceAreaToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :surface_area, :decimal, precision: 6, scale: 2
  end
end
