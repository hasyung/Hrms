class CreateFavNotes < ActiveRecord::Migration
  def change
    create_table :fav_notes do |t|
      t.integer :employee_id, null: false, index: true, comment: '员工ID'

      t.text :note, null: false, comment: '常用备注'

      t.timestamps null: false
    end
  end
end
