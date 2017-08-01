class CreateAgreements < ActiveRecord::Migration
  def change
    create_table :agreements do |t|
      t.integer :employee_id, index: true, comment: '员工ID'
      t.string :employee_no, index: true, comment: '员工编号'
      t.string :employee_name, index: true, comment: '员工姓名'
      t.string :department_name, index: true, comment: '部门名称'
      t.string :position_name, index: true, comment: '岗位名称'
      t.string :apply_type, index: true, comment: '用工性质' #合同制/合同(读取员工当前用工性质)
      t.date :start_date, index: true, comment: '起始日期', null: false
      t.date :end_date, index: true, comment: '终止日期', null: false
      t.string :note, comment: '备注'

      t.timestamps null: false
    end
  end
end
