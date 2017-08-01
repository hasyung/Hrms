class AddDeductLeaveDateToFlows < ActiveRecord::Migration
  def change
    add_column :flows, :deduct_leave_date, :text, index: true
  end
end
