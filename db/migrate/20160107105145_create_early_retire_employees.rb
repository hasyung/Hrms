class CreateEarlyRetireEmployees < ActiveRecord::Migration
  def change
    create_table :early_retire_employees do |t|
      t.string :department, index: true #部门名称,各级部门用“-”连接
      t.string :name, index: true #姓名
      t.string :employee_no, index: true #员工号
      t.string :labor_relation, index: true #用工性质
      t.string :file_no, index: true #文件编号
      t.date   :change_date, index: true #变动时间
      t.string :position, index: true #岗位
      t.string :channel, index: true #通道
      t.string :gender, index: true #性别
      t.date   :birthday, index: true #出生时间
      t.string :identity_no, index: true #身份证号
      t.date   :join_scal_date, index: true #到岗时间
      t.string :remark #备注
      t.timestamps
    end
  end
end
