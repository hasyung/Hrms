class CreateFlowRelations < ActiveRecord::Migration
  def change
    create_table :flow_relations do |t|
      t.string :role_name #角色名称
      t.string :position_ids #岗位集合
      t.string :desc #描述
      t.string :flow_type #flow-type(流程类型)：Flow::AdjustPosition/Flow::EarlyRetirement
      t.integer :department_id #所属部门ID
      t.timestamps null: false
    end

    add_index :flow_relations, :role_name
    add_index :flow_relations, :flow_type
    add_index :flow_relations, :department_id
  end
end
