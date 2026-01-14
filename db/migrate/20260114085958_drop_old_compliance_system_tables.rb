class DropOldComplianceSystemTables < ActiveRecord::Migration[8.0]
  def change
    drop_table :rule_violations, if_exists: true
    drop_table :rules, if_exists: true
  end
end
