class CreateBreakers < ActiveRecord::Migration[8.0]
  def change
    create_table :breakers do |t|
      t.references :residual_current_device, null: false, foreign_key: true
      t.integer :position
      t.integer :max_current
      t.text :description
      t.string :name

      t.timestamps
    end
  end
end
