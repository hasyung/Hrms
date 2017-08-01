class AddLocationToNightFees < ActiveRecord::Migration
  def change
    add_column :night_fees, :location, :string, index: true, comment: "餐费属地化"
  end
end
