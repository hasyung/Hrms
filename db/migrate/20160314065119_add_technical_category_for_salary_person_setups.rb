class AddTechnicalCategoryForSalaryPersonSetups < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :technical_category, :string, index: true, comment: '技术骨干类别'
  end
end
