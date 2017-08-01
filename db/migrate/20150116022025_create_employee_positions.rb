class CreateEmployeePositions < ActiveRecord::Migration
  def change
    create_table :employee_positions do |t|
      t.integer :employee_id
      t.integer :position_id

      t.integer :sort_index, default: 0 #主任，兼任的排序(0代表主要任职)
      t.date      :start_date #到岗时间
      t.date      :end_date #离岗时间
      t.string    :remark #备注

      t.timestamps null: false
    end
  end
end
