class AddFieldsToDinnerRecords < ActiveRecord::Migration
  def change
    add_column :dinner_records, :real_time, :string, comment: '实际时间'
    add_column :dinner_records, :operator, :string, index: true, comment: '操作员'
  end
end
