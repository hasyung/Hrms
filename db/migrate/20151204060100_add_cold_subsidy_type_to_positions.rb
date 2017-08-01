class AddColdSubsidyTypeToPositions < ActiveRecord::Migration
  def change
    add_column :positions, :cold_subsidy_type, :string, default: ""
  end
end
