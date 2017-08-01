class AddHoursFeeCategoryForAirlineFees < ActiveRecord::Migration
  def change
    add_column :airline_fees, :hours_fee_category, :string, index: true, comment: "小时费人员类别"
  end
end
