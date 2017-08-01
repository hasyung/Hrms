class CreateEmployeePersonalInfos < ActiveRecord::Migration
  def change
    create_table :employee_personal_infos do |t|
      t.string :desc1 #描述1
      t.string :desc2 #描述2
      t.string :desc3 #描述3
      t.string :desc4 #描述4
      t.string :desc5 #描述5
      t.string :desc6 #描述6
      t.string :desc7 #描述7
      t.string :desc8 #描述8
      t.string :desc9 #描述9
      t.string :desc10 #描述10
      t.string :desc11 #描述11
      t.string :desc12 #描述12
      t.string :desc13 #描述13
      
      t.integer :employee_id #员工

      t.timestamps null: false
    end
  end
end
