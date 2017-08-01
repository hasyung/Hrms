class CreateAuthenticateToken < ActiveRecord::Migration
  def change
    create_table :authenticate_tokens do |t|
      t.string :token
      t.datetime :expire_at
      t.integer :employee_id

      t.timestamps null: false
    end
  end
end
