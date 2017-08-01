class AddFieldsToNightFees < ActiveRecord::Migration
  def change
    add_column :night_fees, :no, :string, index: true
    add_column :night_fees, :subsidy, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '标准'
    add_column :night_fees, :employee_no, :string, index: true
    add_column :night_fees, :invalid, :boolean, default: false, index: true
  end
end
