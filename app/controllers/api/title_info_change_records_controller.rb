class Api::TitleInfoChangeRecordsController < ApplicationController
	def index
		result = parse_query_params!('title_info_change_record')
		render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    	relations, conditions, sorts, page = result.values

    	@title_info_change_records = TitleInfoChangeRecord.all.order("change_date asc")
		  conditions.each do |condition|
      		@position_change_records = @title_info_change_record.where(condition)
    	end

    	
    	@title_info_change_records = set_page_meta @title_info_change_records, page
	end

    def update
      error = []
      employee = Employee.find_by(id:params[:id])
      render json: {messages: "人员不存在"}, status: 400 and return if employee.nil?
      title_info = {
        employee_id: employee.id,
        prev_job_title: employee.job_title,
        prev_job_title_degree_id: employee.job_title_degree_id,
        prev_technical_duty: employee.technical_duty,
        prev_file_no: employee.title_info_change_records.last.try(:file_no) || "",
        job_title: params[:job_title],
        job_title_degree_id: params[:job_title_degree_id],
        technical_duty: params[:technical_duty],
        file_no: params[:file_no] || "",
        change_date: params[:change_date] || Time.now
      }

      ActiveRecord::Base.transaction do
        begin
          TitleInfoChangeRecord.create(title_info)
          employee.update(job_title: params[:job_title], job_title_degree_id: params[:job_title_degree_id], technical_duty: params[:technical_duty])
        rescue Exception => e
          error << "修改失败"
        end
      end
      render json: {messages: error}, status: 400 and return if error.size != 0
      render json: {messages: "修改成功"}
    end
end