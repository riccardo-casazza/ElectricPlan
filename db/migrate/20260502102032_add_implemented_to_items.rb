class AddImplementedToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :implemented, :boolean, default: true, null: false
  end
end
