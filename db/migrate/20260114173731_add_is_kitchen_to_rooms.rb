class AddIsKitchenToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :is_kitchen, :boolean, default: false
  end
end
