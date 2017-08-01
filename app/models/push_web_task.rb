class PushWebTask
  include Sidekiq::Worker

  def self.notify_alls

    change_record_web_ids = ChangeRecordWeb.where(is_pushed: false)

    if change_record_web_ids.blank?
      return
    end
    ids = []
    change_record_web_ids.each do |change_record_web_id|
      ids << change_record_web_id.id
    end
    Sidekiq.logger.info  "start push task"
    worker =  ChangeRecordDeliverWebWorker.new
    worker.perform(ids)
    Sidekiq.logger.info "end push task"
  end


end