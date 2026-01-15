class AddDwellingToElectricalPanels < ActiveRecord::Migration[8.0]
  def change
    add_reference :electrical_panels, :dwelling, foreign_key: true
  end
end
