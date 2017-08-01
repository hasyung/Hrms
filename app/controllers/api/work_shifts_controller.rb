class Api::WorkShiftsController < ApplicationController
	skip_before_action :check_permission, only: [:show]
	skip_before_action :check_action_register, only: [:show]
  def index
  	result = parse_query_params!('employee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @work_shifts = WorkShift.joins(:employee).where("work_shifts.end_time is null")


    conditions.each do |condition|
     @work_shifts = @work_shifts.where(condition)
    end

    @work_shifts = @work_shifts.where("work_shifts like '%#{params[:work_shifts]}%'") if params[:work_shifts].present?
    @work_shifts = set_page_meta @work_shifts, page

  end

  def edit
    work_shift_id = params[:id]
    work_shifts = params[:work_shifts]
    time_now = Time.now
    
    work_shift = WorkShift.find_by(id: work_shift_id)
    work_shift.update(end_time: time_now)

    employee = Employee.find_by(employee_no: work_shift.employee_no)
    return render json: {messages: "人员不存在"}, status: 400 if employee.nil?
    WorkShift.create(employee_id: employee.id, employee_no: employee.employee_no, work_shifts: work_shifts, start_time: time_now)
    render json: {messages: "修改成功"}
  end

  def create
  	employee_id = params[:employee_id]
  	employee = Employee.find_by(id:employee_id)
  	return render json: {messages: "人员不存在"}, status: 400 if employee.nil?
    return render json: {messages: "人员班制已存在。"}, status: 400 if WorkShift.where(employee_id: employee.id, end_time: nil).present?
  	WorkShift.create(employee_id:employee_id, employee_no:employee.employee_no,work_shifts:params[:work_shifts],start_time:Time.now)
  	render json: {messages: "添加成功"}
  end

  def show
  	@work_shifts = WorkShift.where(id:params[:id])
  	render template: "api/work_shifts/index"
  end

  def import
    attachment = Attachment.find(params[:attachment_id])
    importor = Excel::WorkShiftsImportor.new(attachment.full_path).parse_data
    if importor.errors.size > 0
      render json: {messages: importor.errors.join(",")}, status: 400
    else
      importor.import
      if importor.errors.size > 0
        render json: {messages: importor.errors.join(",")}, status: 400
      else
        render json: {messages: "导入成功"}
      end
    end
  end
end
