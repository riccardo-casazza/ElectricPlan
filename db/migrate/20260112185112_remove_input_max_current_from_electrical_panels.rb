class RemoveInputMaxCurrentFromElectricalPanels < ActiveRecord::Migration[8.0]
  def change
    remove_column :electrical_panels, :input_max_current, :integer
  end
end
