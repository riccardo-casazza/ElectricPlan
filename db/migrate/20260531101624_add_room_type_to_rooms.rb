class AddRoomTypeToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :room_type, :string
  end
end
