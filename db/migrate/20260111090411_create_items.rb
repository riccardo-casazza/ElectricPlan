class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.references :breaker, null: false, foreign_key: true
      t.references :room, null: false, foreign_key: true
      t.string :name
      t.references :item_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
