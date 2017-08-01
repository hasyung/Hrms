class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.integer :employee_id, index: true
      t.string  :title, null: false, comment: '汇报标题'
      t.string  :content, comment: '汇报内容'
      t.string  :checker, comment: '汇报审核角色position_ids'

      t.timestamps null: false
    end
  end
end
