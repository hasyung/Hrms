class CreateEmployeeContactWays < ActiveRecord::Migration
  def change
    create_table :employee_contact_ways do |t|
      t.string :telephone #固定电话
      t.string :mobile #手机号码
      t.string :address #家庭地址
      t.string :mailing_address #通信地址
      t.string :email #电子邮箱
      t.string :postcode #邮政编码
      
      t.integer :employee_id #员工

      t.timestamps null: false
    end
  end
end
