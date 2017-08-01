class AddSubsidyAmountToDinnerRecords < ActiveRecord::Migration
  def change
    add_column :dinner_records, :subsidy_amount, :decimal, precision: 10, scale: 2, index: true, comment: '补贴金额'
  end
end
