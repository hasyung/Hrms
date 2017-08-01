class AddTemperatureAmount < ActiveRecord::Migration
  def change
    add_column :positions, :temperature_amount, :integer, default: 0, index: true, comment: '高温费'
  end
end
