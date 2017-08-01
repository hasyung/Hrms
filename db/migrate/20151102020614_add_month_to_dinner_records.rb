class AddMonthToDinnerRecords < ActiveRecord::Migration
  def change
    add_column :dinner_records, :month, :string, index: true, comment: '月份'
  end
end
