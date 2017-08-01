class Api::Me::MeController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register
  skip_before_action :check_permission

  def show
    @employee = @current_employee
    @master_position = @employee.master_position
    @emp_pos = @employee.employee_positions
    if @employee.languages.blank?
      #如果没有语言，初始化一个
      @employee.languages.create
      @emp_languages = @employee.languages
    else
      @emp_languages = @employee.languages
    end
    @audits = @employee.audits.where(status_cd: 1)
  end

  def resume
    @employee = @current_employee
    @employee.languages.create if @employee.languages.blank? #如果没有语言，初始化一个
    @languages = @employee.languages
    render template: '/shared/resume'
  end

  def export_resume
    resume_service = ExportResumeService.new(@current_employee.id).execute
    send_file(resume_service.path, filename: resume_service.filename)
  end

  def update
    Audit.save_changes(@current_employee, validate_unpass_employee) if validate_unpass_employee.present?
    @audits = @current_employee.audits.where(status_cd: 1)
    if @current_employee.assign_attributes(employee_params)
      @current_employee.me_presence_columns
      if @current_employee.errors.present?
        render json: {messages: @current_employee.errors.values.flatten.join(",")}, status: 400
        return
      end
    end

    mobile = @current_employee.contact.mobile

    if @current_employee.save &&
      @current_employee.contact.update(contact_params) &&
      @current_employee.personal_info.update(personal_info_params)

      @employee = @current_employee.reload

      if @current_employee.contact.mobile != mobile
        @current_employee.annuity_notes.create(category: "mobile")
      end

      @master_position = @employee.master_position
      @emp_pos = @employee.employee_positions

      ChangeRecord.save_record('employee_update', @current_employee).send_notification
      ChangeRecordWeb.save_record('employee_update', @current_employee).send_notification

      render template: '/api/me/me/show'
    else
      render json: {messages: @employee.errors.values.flatten.join(",")}, status: 400
    end
  end

  def update_password
    if @current_employee.has_password?(params["password"]) && params['new_password'] == params['password_confirm']
      @current_employee.password = params['new_password']
      @current_employee.save_without_auditing
      render json: {messages: "密码修改成功"}
    else
      render json: {messages: "密码修改失败"}, status: 400
    end
  end

  def upload_favicon
    @employee = @current_employee
    @master_position = @employee.master_position
    @emp_pos = @employee.employee_positions

    @employee.favicon = params[:file]

    if @employee.save_without_auditing
      render template: '/api/me/me/show'
    else
      render json: {messages: @employee.errors.values.flatten.join(",")}, status: 400
    end
  end

  def leave
    @workflows = Flow.includes(:flow_nodes).where("type in (?)", Flow.leave_types).where(receptor_id: @current_employee.id)
    render template: '/api/workflows/leave'
  end

  def alleges
    @alleges = PerformanceAllege.joins(:performance).order('created_at desc')
      .where("performances.employee_id = ?", @current_employee.id)
    render template: '/api/performance_alleges/index'
  end

  def performances
    @performances = current_employee.performances.includes(:attachments, :allege)
      .order("assess_year DESC")
      .order("assess_time DESC")

    @expire_day = Holiday.before_working_days(5).beginning_of_day
  end

  def annuities
    @annuities = current_employee.annuities.order("cal_date DESC")
    @annuity_status = current_employee.annuity_status
    @annuity_apply_status = current_employee.annuity_applies.where(status: false).present?
    @can_join_annuity = current_employee.labor_relation.try(:display_name) == '合同制' && current_employee.contact.try(:mobile).present?
  end

  def auditor_list
    @employees = Employee.includes(
      [:positions => [:department]]
    ).joins(
      "JOIN departments ON departments.id = employees.department_id", :positions
    ).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    )

    department = Department.find(current_employee.department_id)
    department_ids = Department.where("serial_number like ?", "#{department.serial_number[0..5]}%").pluck(:id)
    @employees = @employees.where("positions.department_id in (?)", department_ids).where("employees.name like ?", "%#{params[:name]}%").uniq
  end

  def punishments
    @punishments = current_employee.punishments.where(genre: '处分')
    render json: {punishments: @punishments}
  end

  def rewards
    @punishments = current_employee.punishments.where(genre: '奖励')
    render json: {rewards: @punishments}
  end

  def attendance_records
    beginning_of_year = Date.today.beginning_of_year
    end_of_year = Date.today.end_of_year

    attendances = current_employee.attendances.where("(record_date >= ?) AND (record_date <= ?)", beginning_of_year, end_of_year)
    @late_or_early_leaves = attendances.late_or_early_leave
    @flight_groundeds = attendances.flight_grounded
    @flight_ground_works = attendances.flight_ground_work
    @absences = attendances.absence
    @leaves = current_employee.own_flows.leaves.actived.where("(updated_at >= ?) AND (updated_at <= ?)", beginning_of_year, end_of_year)
    @employee = current_employee
  end

  def technical_records
    @technical_records = current_employee.technical_records

    render json: {technical_records: @technical_records}
  end

  private
  def employee_params
    safe_params [:native_place, :birth_place, :marital_status_id, :nationality, :nation, :school, :major]
  end

  def unpass_employee_params
    [:name, :identity_no, :gender_id]
  end

  def contact_params
    params[:contact] ? params.require(:contact).permit(:telephone, :mobile, :address, :mailing_address, :email, :postcode) : {}
  end

  def personal_info_params
    params[:personal_info] ? params.require(:personal_info).permit(:desc1, :desc2, :desc3, :desc4, :desc5, :desc6, :desc7, :desc8, :desc9, :desc10, :desc11, :desc12, :desc13) : {}
  end

  def validate_unpass_employee
    unpass = {}
    unpass_employee_params.each do |key|
      if params[key].present? && @current_employee.send(key) != params[key]
        unpass.merge!( { key.to_s => params[key] } )
      end

      if params[:name].present? && @current_employee.send(:identity_name) != params[:name].gsub(/[0-9a-zA-Z]/, '')
        unpass.merge!( { "identity_name" => params[:name].gsub(/[0-9a-zA-Z]/, '') } )
      end
    end
    unpass
  end
end
