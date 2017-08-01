class AddExternalApplicationMail < ActiveRecord::Migration
  def change
    add_column :external_applications, :email,:string, null:  true, comment: '失败邮件地址'
  end
end
