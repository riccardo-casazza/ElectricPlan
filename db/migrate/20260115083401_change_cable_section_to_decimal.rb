class ChangeCableSectionToDecimal < ActiveRecord::Migration[8.0]
  def up
    # Add temporary column
    add_column :cables, :section_numeric, :decimal, precision: 5, scale: 2

    # Migrate existing data: extract numeric value from strings like "1.5 mm²"
    Cable.reset_column_information
    Cable.find_each do |cable|
      if cable.section.present?
        # Extract the numeric part (e.g., "1.5 mm²" -> 1.5)
        numeric_value = cable.section.to_s.gsub(/[^\d.]/, '').to_f
        cable.update_column(:section_numeric, numeric_value)
      end
    end

    # Remove old column and rename new column
    remove_column :cables, :section
    rename_column :cables, :section_numeric, :section
  end

  def down
    # Add back string column
    add_column :cables, :section_string, :string

    # Convert numeric back to string format
    Cable.reset_column_information
    Cable.find_each do |cable|
      if cable.section.present?
        cable.update_column(:section_string, "#{cable.section} mm²")
      end
    end

    # Remove numeric column and rename string column
    remove_column :cables, :section
    rename_column :cables, :section_string, :section
  end
end
