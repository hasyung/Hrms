class CreateSpecialStates < ActiveRecord::Migration
  def change
    create_table :special_states, :comment => "员工异动信息表" do |t|
      t.integer :employee_id,     index: true, null: false, :comment => "员工ID"
      t.integer :department_id,   index: true, :comment => "异动至部门ID"
      t.boolean :out_company,     index: true, :comment => "异动到公司外?"
      t.string :special_category, index: true, null: false, :comment => "异动性质"
      t.string :special_location, index: true, :comment => "异动地点"
      t.date :special_date_from,  index: true, null: false, :comment => "异动开始时间"
      t.date :special_date_to,    index: true, null: false, :comment => "异动结束时间"

      t.timestamps null: false
    end
  end
end
