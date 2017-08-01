class AddIsDeductedAndIsAdjustedToFlows < ActiveRecord::Migration
  def change
    add_column :flows, :is_deducted, :boolean, index:true, default: false
    add_column :flows, :is_adjusted, :boolean, index:true, default: false
    add_column :flows, :leave_date_record, :text, index: true
  end
end
