class AddMergeStatusForContracts < ActiveRecord::Migration
  def change
    add_column :contracts, :original, :boolean, default: true
    add_column :contracts, :merged, :boolean, default: false
  end
end
