class AddIsUnfixForContracts < ActiveRecord::Migration
  def change
    add_column :contracts, :is_unfix, :boolean, default: false, index: true, comment: '是否为无固定'
  end
end
