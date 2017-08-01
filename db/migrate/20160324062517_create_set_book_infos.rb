class CreateSetBookInfos < ActiveRecord::Migration
  def change
    create_table :set_book_infos do |t|
      t.integer :employee_id, index: true
      t.string :bank_no, index: true, comment: '帐套工资存折号'
      t.string :salary_category, index: true, comment: '帐套薪酬类别'
      t.string :employee_category, index: true, comment: '帐套用工类别编码'

      t.timestamps null: false
    end
  end
end
