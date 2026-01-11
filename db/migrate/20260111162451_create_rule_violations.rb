class CreateRuleViolations < ActiveRecord::Migration[8.0]
  def change
    create_table :rule_violations do |t|
      t.references :rule, null: false, foreign_key: true
      t.string :resource_type
      t.integer :resource_id
      t.string :severity
      t.text :message
      t.json :context
      t.boolean :resolved, default: false

      t.timestamps
    end

    add_index :rule_violations, [:resource_type, :resource_id]
  end
end
