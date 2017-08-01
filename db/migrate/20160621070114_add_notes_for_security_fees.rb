class AddNotesForSecurityFees < ActiveRecord::Migration
  def change
  	add_column :security_fees, :notes, :string, index: true, comment: '计算过程备注'
  end
end
