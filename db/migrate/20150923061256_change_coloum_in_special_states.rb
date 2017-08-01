class ChangeColoumInSpecialStates < ActiveRecord::Migration
  def change
    change_column :special_states, :special_date_to, :date, index: true, null: true
  end
end
