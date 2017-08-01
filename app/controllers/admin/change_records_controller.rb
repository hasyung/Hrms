class Admin::ChangeRecordsController < AdminController
  def index
  end

  def failed
    @change_records = ChangeRecord.where(is_pushed: false)
      .where("created_at >= ?", "2016-07-01")
      .paginate(:page => params[:page], :per_page => 20)
      .order('created_at DESC')
  end

  def send_again
    @record = ChangeRecord.find params[:id]
    @record.send_notification
    redirect_to action: :failed
  end

  def export
    @change_records = ChangeRecord.all
    @change_records = @change_records.where(change_type: params[:change_type]) unless params[:change_type].blank?
    @change_records = @change_records.where("date(event_time) >= '#{params[:start_date]}'") unless params[:start_date].blank?
    @change_records = @change_records.where("date(event_time) <= '#{params[:end_date]}'") unless params[:end_date].blank?

    excel = Excel::ChangeRecordsExportor.export(@change_records)
    send_file(excel[:path], filename: excel[:filename])
  end
end
