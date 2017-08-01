class ChangeDaysFormatInVacationRecord < ActiveRecord::Migration
  def change
    change_column :vacation_records, :days, :float, index: true, default: 0
  end
end
