class RemoveSearchConditionsIndexForPermissions < ActiveRecord::Migration
  def change
    Permission.where(controller: "search_conditions", action: "index").first.try(:destroy)
  end
end
