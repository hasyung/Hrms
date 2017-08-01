class CreateBusFees < ActiveRecord::Migration
  def change
    create_table :bus_fees do |t|
    	t.integer :employee_id, index: true
      t.string :employee_no, comment: '人员编号'
      t.string :employee_name, index: true, comment: '人员名称'
      t.string :department_name, comment: '机构名称'
      t.string :position_name, comment: '岗位名称'
      t.string :month, index: true, comment: '月份'

      t.decimal :fee, precision: 10, scale: 2, default: 0, index: true, comment: '班车费'
      t.decimal :add_garnishee, precision: 10, scale: 2, default: 0, index: true, comment: '补扣发'
      t.decimal :total, precision: 10, scale: 2, default: 0, index: true, comment: '合计'
      t.string :remark, comment: '备注'

      t.timestamps null: false
    end

    remove_column :employees, :bus_fee
    remove_column :transport_fees, :bus_fee

    add_column :birth_salaries, :bus_fee, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '班车费'
    add_column :salary_overviews, :bus_fee, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '班车费'
  end
end
