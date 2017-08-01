class CreateKeepSalaries < ActiveRecord::Migration
  def change
    create_table :keep_salaries do |t|
      t.integer :employee_id, null: false, index: true
      t.string  :employee_name, index: true, comment: '姓名'
      t.string  :employee_no, index: true, comment: '员工编码'
      t.string  :department_name, index: true, comment: '所属部门'
      t.string  :position_name, index: true, comment: '岗位'
      t.integer :channel_id, index: true, comment: '通道ID'

      t.decimal :position, precision: 10, scale: 2, index: true, comment: '岗位工资保留'
      t.decimal :performance, precision: 10, scale: 2, index: true, comment: '业绩奖保留'
      t.decimal :working_years, precision: 10, scale: 2, index: true, comment: '工龄工资保留'
      t.decimal :minimum_growth, precision: 10, scale: 2, index: true, comment: '保底增幅'
      t.decimal :land_allowance, precision: 10, scale: 2, index: true, comment: '地勤补贴保留'
      t.decimal :life_allowance, precision: 10, scale: 2, index: true, comment: '生活补贴保留'
      t.decimal :adjustmen_09, precision: 10, scale: 2, index: true, comment: '09调资增加保留'
      t.decimal :bus_14, precision: 10, scale: 2, index: true, comment: '14公务用车保留'
      t.decimal :communication_14, precision: 10, scale: 2, index: true, comment: '14通信补贴保留'

      t.decimal :add_garnishee, comment: '补扣发'
      t.string  :remark, comment: '备注'
      t.string :month, index: true, comment: '月份'
      t.timestamps null: false
    end
  end
end
