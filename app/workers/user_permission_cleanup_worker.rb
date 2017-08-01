class EmployeePermissionCleanupWorker
  include Sidekiq::Worker

  def perform(*args)
    EmployeePermission.cleanup
  end
end
