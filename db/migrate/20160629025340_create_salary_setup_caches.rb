class CreateSalarySetupCaches < ActiveRecord::Migration
  def change
    create_table :salary_setup_caches do |t|
      t.integer :channel_id, index: true
      t.integer :salary_change_id, index: true
      t.integer :prev_channel_id, index: true
    	t.date    :position_change_date, index: true
      t.date    :probation_end_date, index: true
      t.text    :data  #数据
      t.boolean :is_confirmed, default: false, index: true

      t.integer :employee_id, index: true  #员工

      t.timestamps null: false
    end
  end
end
