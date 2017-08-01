class FixInvalidForNightFees < ActiveRecord::Migration
  def change
    rename_column :night_fees, :invalid, :is_invalid
  end
end
