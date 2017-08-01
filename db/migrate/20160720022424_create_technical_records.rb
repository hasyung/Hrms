class CreateTechnicalRecords < ActiveRecord::Migration
  def change
    create_table :technical_records do |t|
    	t.integer :employee_id, index: true
    	t.string  :technical, index: true
    	t.string  :file_no, index: true
    	t.date    :change_date, index: true

      t.timestamps null: false
    end

    add_column :employees, :technical, :string, index: true, comment: '技术等级'
  end
end
