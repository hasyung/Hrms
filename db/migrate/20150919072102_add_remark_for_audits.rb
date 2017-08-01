class AddRemarkForAudits < ActiveRecord::Migration
  def change
    add_column :audits, :remark, :string, index: true
  end
end
