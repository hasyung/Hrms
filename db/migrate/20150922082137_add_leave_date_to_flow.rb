class AddLeaveDateToFlow < ActiveRecord::Migration
  def change
    add_column :flows, :start_leave_date, :date
    add_column :flows, :end_leave_date, :date
  end
end
