class CreateAnnuityNotes < ActiveRecord::Migration
  def change
    create_table :annuity_notes do |t|
      t.integer :employee_id
      t.string  :category

      t.timestamps null: false
    end
  end
end
