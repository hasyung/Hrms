class AddGenreForPunishments < ActiveRecord::Migration
  def change
    add_column :punishments, :genre, :string, index: true, default: '处分'
    add_column :punishments, :reward_date, :date, index: true
  end
end
