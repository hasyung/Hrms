class AddSpecialControllerActionsToEmplaroyees < ActiveRecord::Migration
  def change
    add_column :employees, :special_ca, :text
  end
end
