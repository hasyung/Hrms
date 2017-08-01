class AddImportMonthFromCabinVacationImports < ActiveRecord::Migration
  def change
    add_column :cabin_vacation_imports, :import_month, :string
  end
end
