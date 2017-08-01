class CreateSocialCardinalities < ActiveRecord::Migration
  def change
    create_table :social_cardinalities do |t|
      t.integer :employee_id, null: false, index: true

      t.string  :employee_no
      t.string  :employee_name
      t.string  :department_name
      t.string  :position_name
      t.string  :social_account #社保账号
      t.float   :total #合计
      t.integer :cardinality #基数
      t.string  :import_month

      t.timestamps null: false
    end
  end
end
