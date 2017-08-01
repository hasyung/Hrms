class AddGenderNameToPositionRecord < ActiveRecord::Migration
  def change
    add_column :position_records, :gender_name, :string
  end
end
