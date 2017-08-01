class CreatePermission < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.string :category
      t.string :controller  #Rails Controller
      t.string :action  #Rails Action
      t.string :rw_type, default: 'read'  #读写类型
      t.string :bit_value, default: '0' #权限
      t.string :channel, default: 'none' #???
      t.string :channel_value #??

      t.timestamps null: false
    end
  end
end
