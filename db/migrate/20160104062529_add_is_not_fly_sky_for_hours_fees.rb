class AddIsNotFlySkyForHoursFees < ActiveRecord::Migration
  def change
    add_column :hours_fees, :is_not_fly_sky, :boolean, index: true, default: false, comment: '是否模拟带教，没有飞上天'
  end
end
