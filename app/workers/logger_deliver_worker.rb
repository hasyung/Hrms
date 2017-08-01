class LoggerDeliverWorker
  include Sidekiq::Worker

  def perform(project, employee_name, str)
  	DrbLogger.get_logger.write(project, employee_name, str)
  end
end
