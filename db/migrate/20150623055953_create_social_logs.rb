class CreateSocialLogs < ActiveRecord::Migration
  def change
    create_table :social_logs do |t|
      t.integer :employee_id, null: false, index: true

      t.string  :employee_name, index: true
      t.string  :employee_no, index: true
      t.string  :department_name, index: true

      t.string  :category, index: true
      t.string  :state, default: '未处理', index: true

      t.string  :indentity_no_was, index: true
      t.string  :location_was, index: true

      t.timestamps null: false
    end
  end
end
