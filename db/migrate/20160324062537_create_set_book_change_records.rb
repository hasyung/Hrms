class CreateSetBookChangeRecords < ActiveRecord::Migration
  def change
    create_table :set_book_change_records do |t|
      t.integer :employee_id, index: true
      t.string :category, index: true

      t.string :old_bank_no, index: true, comment: '原帐套工资存折号'
      t.string :new_bank_no, index: true, comment: '新帐套工资存折号'

      t.string :old_deparment_name, comment: '原部门名称'
      t.string :new_deparment_name, comment: '现在部门名称'

      t.string :old_deparment_set_book_no, index: true, comment: '原部门帐套编码'
      t.string :new_deparment_set_book_no, index: true, comment: '现部门帐套编码'

      t.string :old_salary_category, index: true, comment: '原帐套薪酬类别'
      t.string :new_salary_category, index: true, comment: '现帐套薪酬类别'

      t.string :old_employee_category, index: true, comment: '原帐套用工类别编码'
      t.string :new_employee_category, index: true, comment: '现帐套用工类别编码'

      t.timestamps null: false
    end
  end
end
