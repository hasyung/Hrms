class CreateFlowPunishments < ActiveRecord::Migration
  def change
    create_table :flow_punishments do |t|

      t.timestamps null: false
    end
  end
end
