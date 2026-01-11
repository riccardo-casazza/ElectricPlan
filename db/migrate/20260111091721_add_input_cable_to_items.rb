class AddInputCableToItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :items, :input_cable, foreign_key: { to_table: :cables }
  end
end
