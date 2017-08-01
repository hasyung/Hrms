class AddBusFeeForEmployees < ActiveRecord::Migration
  def change
  	add_column :employees, :bus_fee, :integer, default: 0, index: true, comment: '当前要扣除的班车费，放弃班车费，该字段为0'
  end
end
