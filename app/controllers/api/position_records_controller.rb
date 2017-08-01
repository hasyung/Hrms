class Api::PositionRecordsController < ApplicationController
  before_filter :get_records

  def index
    @records = set_page_meta @records, @page
  end

  def export
    if @records.present?
      excel = Excel::PositionRecordWriter.export(@records)
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
      render text: ''
    end
  end

  private
  def get_records
    result = parse_query_params!('position_record')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?

    relations, conditions, sorts, @page = result.values

    @records = PositionRecord.all.order(created_at: :desc)
    @records = @records.where(id: params[:record_ids].split(',')) if params[:record_ids]

    conditions.each do |condition|
      @records = @records.where(condition)
    end
  end
end
