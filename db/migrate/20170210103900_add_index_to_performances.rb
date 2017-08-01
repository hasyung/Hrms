class AddIndexToPerformances < ActiveRecord::Migration
  def change
    add_index :performances, :employee_id
    add_index :performances, :employee_name
    add_index :performances, :employee_no
    add_index :performances, :department_name
    add_index :performances, :position_name
    add_index :performances, :channel
    add_index :performances, :assess_time
    add_index :performances, :result
    add_index :performances, :sort_no
    add_index :performances, :employee_category
    add_index :performances, :created_at
    add_index :performances, :updated_at
    add_index :performances, :department_distribute_result
    add_index :performances, :month_distribute_base
    add_index :performances, :department_reserved
    add_index :performances, :category
    add_index :performances, :assess_year
    add_index :performances, :category_name
    add_index :performances, :department_id
    add_index :performances, :is_leader
    
  end
end
