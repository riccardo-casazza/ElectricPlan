class AddInputCableToElectricalPanels < ActiveRecord::Migration[8.0]
  def change
    add_reference :electrical_panels, :input_cable, foreign_key: { to_table: :cables }
  end
end
