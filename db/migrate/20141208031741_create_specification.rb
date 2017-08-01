class CreateSpecification < ActiveRecord::Migration
  def change
    create_table :specifications do |t|
      t.text :duty  #工作职责
      t.text :personnel_permission  #人事权限
      t.text :financial_permission  #财务权限
      t.text :business_permission #业务权限
      t.text :superior  #直属上级
      t.text :underling #直属下级
      t.text :internal_relation #内部联系
      t.text :external_relation #外部联系
      t.text :qualification #任职条件

      t.integer :position_id  #岗位

      t.index :position_id

      t.timestamps null: false
    end
  end
end
