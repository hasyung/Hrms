class AddClassificationPositionChangeRecords < ActiveRecord::Migration
  def change
    add_column :position_change_records, :classification, :string, index: true, comment: '类别'
  end
end
