class AddIsCustomToHoliday < ActiveRecord::Migration
  def change
    add_column :holidays, :is_custom, :boolean, default: false, index: true, comment: "自定义?"
    add_column :holidays, :note, :string, comment: "备注"
  end
end
