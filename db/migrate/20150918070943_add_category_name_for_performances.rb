class AddCategoryNameForPerformances < ActiveRecord::Migration
  def change
    if Performance.attribute_names.exclude?('category_name')
      add_column :performances, :category_name, :string, index: true
    end
  end
end
