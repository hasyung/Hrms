class AddSomeColumnsForSalaryChanges < ActiveRecord::Migration
  def change
  	add_column :salary_changes, :prev_channel_id, :integer, index: true

  	add_column :salary_setup_caches, :prev_category_id, :integer, index: true
  	add_column :salary_setup_caches, :prev_department_name, :string, index: true
  	add_column :salary_setup_caches, :prev_position_name, :string, index: true
  	add_column :salary_setup_caches, :prev_location, :string, index: true
  end
end
