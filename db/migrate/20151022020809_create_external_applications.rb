class CreateExternalApplications < ActiveRecord::Migration
  def change
    create_table :external_applications do |t|
      t.string :application_name
      t.string :company_name
      t.text :description
      t.string :api_key, comment: '接口应用标识'
      t.string :api_secret, comment: '秘钥'
      t.integer :call_count, default: 0, index: true, comment: '调用次数'
      t.timestamps null: false
    end
  end
end
