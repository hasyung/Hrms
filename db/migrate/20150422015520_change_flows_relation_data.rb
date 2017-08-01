class ChangeFlowsRelationData < ActiveRecord::Migration
  def change
    change_column :flows, :relation_data, :text
  end
end
