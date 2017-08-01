class AddIsContinueVacationForTransportFees < ActiveRecord::Migration
  def change
  	add_column :transport_fees, :is_continue_vacation, :boolean, default: false, index: true, comment: '是否请假天数大于 15 天，交通费减半'
  end
end
