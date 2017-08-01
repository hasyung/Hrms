class AddMaterialHandlingSubsidyToAllowances < ActiveRecord::Migration
  def change
    add_column :allowances, :material_handling_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "航材搬运补贴"
  end
end
