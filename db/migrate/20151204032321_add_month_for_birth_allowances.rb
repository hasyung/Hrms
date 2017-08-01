class AddMonthForBirthAllowances < ActiveRecord::Migration
  def change
    add_column :birth_allowances, :month, :string, index: true, comment: '最后抵扣月份'
  end
end
