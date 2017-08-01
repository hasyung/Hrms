class AddIsVirtualToDepartments < ActiveRecord::Migration
  def change
    add_column :departments, :is_virtual, :boolean, default: false, index: true
    
    Department.where("name='商旅公司' or name='文化传媒广告公司' or name='校修中心'").update_all(is_virtual: true)
  end
end
