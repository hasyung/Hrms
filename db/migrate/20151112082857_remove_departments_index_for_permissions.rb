class RemoveDepartmentsIndexForPermissions < ActiveRecord::Migration
  def change
    Permission.where(controller: "departments", action: "index").first.try(:destroy)
  end
end
