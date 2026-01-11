class CreateRules < ActiveRecord::Migration[8.0]
  def change
    create_table :rules do |t|
      t.text :description
      t.text :rule
      t.string :applies_to

      t.timestamps
    end
  end
end
