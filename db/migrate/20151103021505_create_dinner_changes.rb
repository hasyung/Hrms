class CreateDinnerChanges < ActiveRecord::Migration
  def change
    create_table :dinner_changes do |t|
      t.integer :employee_id, index: true, comment: '员工id'
      t.string :employee_name, index: true, comment: '员工姓名'
      t.string :employee_no, index: true, comment: '员工编号'
      t.string :category, index: true, comment: '变动种类'
      t.timestamps null: false
    end
  end
end
