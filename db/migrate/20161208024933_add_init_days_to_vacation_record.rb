class AddInitDaysToVacationRecord < ActiveRecord::Migration
  def change
    add_column :vacation_records, :init_days, :integer, index: true, comment: '初始化天数'
  end
end
