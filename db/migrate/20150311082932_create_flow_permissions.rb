class CreateFlowPermissions < ActiveRecord::Migration
  def change
    create_table :flow_permissions do |t|
      t.string :category
      t.string :workflow  #流程
      t.string :node  #节点
      t.string :flow_bit_value, default: '0' #权限

      t.timestamps null: false
    end
  end
end
