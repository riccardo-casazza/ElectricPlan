class CreateDwellings < ActiveRecord::Migration[8.0]
  def change
    create_table :dwellings do |t|
      t.string :name

      t.timestamps
    end
  end
end
