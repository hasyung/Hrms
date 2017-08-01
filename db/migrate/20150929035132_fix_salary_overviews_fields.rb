class FixSalaryOverviewsFields < ActiveRecord::Migration
  def change
    rename_column :salary_overviews, :subdidy, :subsidy
    rename_column :salary_overviews, :land_subdidy, :land_subsidy
  end
end
