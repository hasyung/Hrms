class CreateFlows < ActiveRecord::Migration
  def change
    create_table :flows do |t|
      t.string :name
      t.integer :sponsor_id
      t.integer :receptor_id
      t.string :reviewer_ids
      t.string :type #小分类，如：事假、病假等
      t.string :workflow_state, default: 'new'
      t.string :category #大分类，如：请假、转正等
      t.string :form_data #业务数据.Hash
      t.string :relation_data #HTML页面数据

      t.timestamps null: false
    end
  end
end
