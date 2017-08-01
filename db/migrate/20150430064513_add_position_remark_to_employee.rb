class AddPositionRemarkToEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :position_remark, :string
  end
end
