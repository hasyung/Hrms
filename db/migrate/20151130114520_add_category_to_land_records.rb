class AddCategoryToLandRecords < ActiveRecord::Migration
  def change
    add_column :land_records, :category, :string, index: true, comment: '分类'
  end
end
