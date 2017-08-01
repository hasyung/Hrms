class PerformanceUpgradeWorker
  include Sidekiq::Worker
  sidekiq_options unique_for: 15.minutes

  def perform(employee_id)
    SalaryPersonSetup.check_performance_upgrade(employee_id)
  end
end
