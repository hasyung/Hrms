class RemoveHistoryDepartmentsExportToXlsForPermissions < ActiveRecord::Migration
  def change
    Permission.where(controller: "history/departments", action: "export_to_xls").first.try(:destroy)
  end
end
