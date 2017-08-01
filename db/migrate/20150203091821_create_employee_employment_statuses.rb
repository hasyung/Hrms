class CreateEmployeeEmploymentStatuses < ActiveRecord::Migration
  def change
    create_table :employee_employment_statuses do |t|
      t.string :name #名称
      t.string :display_name

      t.timestamps null: false
    end
  end
end
