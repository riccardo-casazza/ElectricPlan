class AddInputMaxCurrentToElectricalPanels < ActiveRecord::Migration[8.0]
  def change
    add_column :electrical_panels, :input_max_current, :integer
  end
end
