class CreateCables < ActiveRecord::Migration[8.0]
  def change
    create_table :cables do |t|
      t.string :section

      t.timestamps
    end
  end
end
