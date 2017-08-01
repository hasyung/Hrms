class CreateAttachment < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.string :path
      t.integer :size, default: 0
      t.string :mimetype

      t.integer :user_id
      t.integer :attachmentable_id
      t.string :attachmentable_type

      t.index :user_id
      t.index :attachmentable_id
      t.index :attachmentable_type
      
      t.timestamps null: false
    end
  end
end
