class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.string :employee_no
      t.string :employee_name
      t.string :response_status
      t.string :message
      t.string :permission_message
      t.string :rw_type
      t.string :request_ip
      t.text :params

      t.timestamps null: false
    end
  end
end
