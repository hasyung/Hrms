class CreateEmployeeFamilyMembers < ActiveRecord::Migration
  def change
    create_table :employee_family_members do |t|
      t.string :name #姓名
      t.string :native_place #籍贯
      t.date   :birthday #出生日期
      t.date   :start_work_date #参加工作时间
      t.date   :married_date #结婚时间
      t.string :gender #性别
      t.string :nation #民族
      t.string :position #岗位
      t.string :company #公司或学校
      t.string :mobile #电话
      t.string :identity_no #身份证号
      t.string :residence_booklet #户口地址
      t.string :political_status #政治面貌
      t.string :education_background #教育背景
      t.string :relation_type #标识子女, 配偶, 父母(中文)
      t.string :relation #标识子女, 配偶, 父母(英文)

      t.integer :employee_id

      t.timestamps null: false
    end
  end
end
