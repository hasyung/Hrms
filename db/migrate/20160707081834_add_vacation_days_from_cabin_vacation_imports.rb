class AddVacationDaysFromCabinVacationImports < ActiveRecord::Migration
  def change
    add_column :cabin_vacation_imports, :vacation_days, :float
  end
end
