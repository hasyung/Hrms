class RemoveVacationDaysFromCabinVacationImports < ActiveRecord::Migration
  def change
    remove_column :cabin_vacation_imports, :vacation_days, :integer
  end
end
