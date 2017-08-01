class AddChangeDateForDinnerChanges < ActiveRecord::Migration
  def change
    add_column :dinner_changes, :change_date, :date, index: true, comment: '信息发生时间'
  end
end
