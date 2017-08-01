class ChangeModelAboutDinnerChanges < ActiveRecord::Migration
  def change
    add_column :dinner_changes, :leave_type, :string, index: true, comment: '请假类别'
    add_column :dinner_changes, :start_date, :date, index: true, comment: '开始时间'
    add_column :dinner_changes, :end_date, :date, index: true, comment: '结束时间'
    add_column :dinner_changes, :point, :string, index: true, comment: '地点'
  end
end
