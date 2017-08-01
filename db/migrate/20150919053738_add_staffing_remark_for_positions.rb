class AddStaffingRemarkForPositions < ActiveRecord::Migration
  def change
    add_column :positions, :staffing_remark, :string, index: true
  end
end
