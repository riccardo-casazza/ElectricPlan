class RenameMaxCurrentToOutputMaxCurrentInBreakers < ActiveRecord::Migration[8.0]
  def change
    rename_column :breakers, :max_current, :output_max_current
  end
end
