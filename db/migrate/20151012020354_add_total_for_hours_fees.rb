class AddTotalForHoursFees < ActiveRecord::Migration
  def change
    add_column :hours_fees, :total, :decimal, precision: 10, scale: 2, index: true, comment: '小合计'
  end
end
