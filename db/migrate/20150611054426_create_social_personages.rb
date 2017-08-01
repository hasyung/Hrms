class CreateSocialPersonages < ActiveRecord::Migration
  def change
    create_table :social_personages do |t|
      t.integer :employee_id, null: false, index: true

      t.string  :social_location #社保属地
      t.string  :employee_no
      t.string  :employee_name
      t.string  :department_name
      t.string  :position_name
      
      t.boolean :pension, default: true, index: true #养老
      t.boolean :treatment, default: true, index: true #医疗
      t.boolean :unemploy, default: true, index: true #失业
      t.boolean :injury, default: true, index: true #工伤
      t.boolean :illness, default: true, index: true #大病
      t.boolean :fertility, default: true, index: true #生育

      t.timestamps null: false
    end
  end
end
