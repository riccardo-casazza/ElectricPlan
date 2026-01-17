class AddLocationToDwellings < ActiveRecord::Migration[8.0]
  def change
    add_column :dwellings, :country_code, :string
    add_column :dwellings, :region_code, :string
    add_column :dwellings, :department_code, :string
  end
end
