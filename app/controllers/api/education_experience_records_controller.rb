class Api::EducationExperienceRecordsController < ApplicationController
  include ExceptionHandler

  before_action :get_education_experience_records

  def index
    @education_experience_records = set_page_meta @education_experience_records, @page
  end

  def export_to_xls
    if @education_experience_records.blank?
      Notification.send_system_message(@current_employee.id, {error_messages: '导出数据为空'})
      return render text: ''
    end

    excel = Excel::EducationExperienceExportor.export(@education_experience_records)
    send_file(excel[:path], filename: excel[:filename])
  end

  private
  def get_education_experience_records
    result = parse_query_params!('education_experience_record')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, @page = result.values

    @education_experience_records = EducationExperienceRecord.includes(employee: [:department, :employee_positions]).order(change_date: :desc)

    conditions.each do |condition|
      @education_experience_records = @education_experience_records.where(condition)
    end
  end

end
