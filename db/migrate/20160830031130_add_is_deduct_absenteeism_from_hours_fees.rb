class AddIsDeductAbsenteeismFromHoursFees < ActiveRecord::Migration
  def change
    add_column :hours_fees, :is_deduct_absenteeism, :boolean, default: false, index: true, comment: '是否已抵扣旷工'
  end
end
