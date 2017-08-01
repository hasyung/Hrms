class AddViewerIdsForFlow < ActiveRecord::Migration
  def change
    add_column :flows, :viewer_ids, :string
  end
end
