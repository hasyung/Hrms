class Api::EmployeesController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register, only: [:permissions, :avatar_url, :flow_leader_index]
  skip_before_action :check_permission, only: [:permissions, :avatar_url, :flow_leader_index]
  skip_before_action :authenticate_user!, only: [:avatar_url]

  skip_after_action :record_log, only: [:avatar_url]

  def index
    if params[:department_id]
      get_employees
      @employees = @employees.where(department_id: params[:department_id]).uniq
    else
      result = parse_query_params!('employee')
      render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
      relations, conditions, sorts, page = result.values
      get_employees
      @employees = @employees.joins(relations).order(sorts)

      conditions.each do |condition|

        # 进行语言查询
        if condition.first == QuerySetting.employee.language_name.sql
          employee_ids = Language.where(employee_id: @employees.map(&:id)).inject([]) do |result, language|
            if language.name == condition.last
              result << language.employee_id
            end
            result
          end
          @employees = @employees.where(id: employee_ids)
          next
        end

        if condition.first == QuerySetting.employee.language_grade.sql
          employee_ids = Language.where(employee_id: @employees.map(&:id)).inject([]) do |result, language|
            if language.grade.present? && language.grade.include?(params[:language_grade])
              result << language.employee_id
            end
            result
          end
          @employees = @employees.where(id: employee_ids)
          next
        end

        # 进行员工查询
        if condition.first == QuerySetting.employee.new_join_date.sql
          condition[3], condition[4] = condition[1], condition[2]
          @employees = @employees.unscope(:order).order("created_at desc")
        end

        # 参工时间查询特殊处理
        if condition.first == QuerySetting.employee.start_work_date.sql
          condition[3], condition[4] = condition[1], condition[2]
        end

        #入职时间查询特殊处理
        if condition.first == QuerySetting.employee.join_scal_date.sql
          condition[3], condition[4] = condition[1], condition[2]
        end

        @employees = @employees.where(condition)
      end

      if(params[:filter_types].present?)
        @flow = Flow.where("type in (?) and workflow_state in (?)", params[:filter_types], Flow.employee_filter_states)
        @employees = @employees.where("employees.id not in (?)", @flow.map(&:receptor_id)) if @flow.present?
        if params[:filter_types] == ["Flow::Retirement"]
          labor_relation_ids = Employee::LaborRelation.where("display_name = '合同' or display_name = '合同制'").map(&:id)
          @employees = @employees.where("employees.labor_relation_id in (?)", labor_relation_ids)
        end
      end

      @employees = set_page_meta @employees.uniq, page
    end
  end

  def search
    result = parse_query_params!('employee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @employees = Employee.unscoped.includes(
      [
        :job_title_degree, :political_status, :education_background,\
        :contact, :master_positions, :category, :department, :employee_positions,\
        :languages, :positions => [:department]
      ]
    ).joins(
      "JOIN departments ON departments.id = employees.department_id"
    ).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    )

    conditions.each do |condition|
      @employees = @employees.where(condition)
    end

    @employees = set_page_meta @employees.uniq, page
    render template: 'api/employees/index'
  end

  # 更新员工的学历
  def change_education
    @employee = Employee.includes(:education_background, :degree).find(params[:id])

    if @employee.blank?
      render json: {messages: '没有找到该员工'}, status: 400 and return
    end

    @change_data = education_info_params

    if @change_data[:graduate_date].blank? || @change_data[:graduate_date].blank?
      render json: {messages: '毕业时间或者变更时间为空'}, status: 400 and return
    end

    if @change_data[:education_background_id].blank? || @change_data[:degree_id].blank?
      render json: {messages: '请选择新的学历和学位'}, status: 400 and return
    end

    @change_data[:graduate_date] = Date.parse(@change_data[:graduate_date])
    @change_data[:change_education_date] = Date.parse(@change_data[:change_education_date])

    if @employee.has_changed_education?(@change_data)
      @change_data[:old_education_data] = {
        education: @employee.try(:education_background).try(:display_name),
        degree: @employee.try(:degree).try(:display_name),
        school: @employee.school,
        major: @employee.major,
        graduate_date: @employee.try(:graduate_date).try(:strftime, "%Y-%m-%d")
      }

      @employee.assign_attributes(@change_data)
      if @employee.save
        Employee::EducationExperience.create({
          school: @change_data[:school],
          major: @change_data[:major],
          graduation_date: @change_data[:graduate_date],
          education_background_id: @change_data[:education_background_id],
          degree_id: @change_data[:degree_id],
          category: 'after',
          employee_id: @employee.id
        })

        EducationExperienceRecord.create({
          school: @change_data[:school],
          major: @change_data[:major],
          graduation_date: @change_data[:graduate_date],
          education_background_id: @change_data[:education_background_id],
          degree_id: @change_data[:degree_id],
          change_date: @change_data[:change_education_date],
          employee_id: @employee.id,
          employee_name: @employee.name,
          employee_no: @employee.employee_no,
          department_name: @employee.department.full_name
        })
      end
      ChangeRecordWeb.save_record("employee_update", @employee).send_notification
      render json: {messages: '学历变更成功'} and return
    else
      render json: {messages: '学历信息没有发生变化'}, status: 400
    end
  end

  def simple_index
    department = get_assign_department(@current_employee.department)
    ids = Department.get_self_and_childrens([department.id])

    @employees = Employee.includes(
      :master_positions, :department
    ).joins(
      :positions, :category
    ).where(
    "positions.department_id in (?) and code_table_categories.display_name in ('领导', '干部')", ids
    ).uniq
  end

  def flow_leader_index
    employee = Employee.find params[:employee_id] || @current_employee

    department = employee.department

    leader_dep_ids = department.parent_chain_exclude_self.inject([]) do |ids, dep|
      ids << dep.childrens.where("name like ?", "%领导").first
      ids
    end.compact
    ids = (department.parent_chain.map{|d| d.id} + leader_dep_ids.map{|d| d.id}).uniq
    @employees = Employee.includes(
      :master_positions, :department
    ).joins(
      :positions, :category
    ).where(
    "positions.department_id in (?) and code_table_categories.display_name in ('领导', '干部')", ids
    ).uniq
    render template: 'api/employees/simple_index'
  end

  def performances
    @employee = Employee.find params[:id]
    @performances = @employee.performances.includes(:attachments, :allege)
      .order("assess_year DESC")
      .order("assess_time DESC")

    @expire_day = Holiday.before_working_days(5).beginning_of_day
  end

  def avatar_url
    @employee = Employee.find_by(employee_no: params[:employee_no])
    @url = Setting.upload_url + @employee.favicon.big.url if @employee.present? && @employee.favicon.present?
    render json: {url: @url}
  end

  def permissions
    if current_employee.try(:is_admin) && current_employee.try(:name).to_s == 'administrator'
      @employee = Employee.unscoped.find_by(name: params[:name])
    else
      @employee = Employee.find_by(name: params[:name])
    end

    render json: {messages: '人员不存在'}, status: 404 and return unless @employee
    permissions = @employee.get_all_controller_actions.inject([]){|arr, p|arr << (p.controller + '_' + p.action)}
    roles_permissions = @employee.get_roles_controller_actions.inject([]){|arr, p|arr << (p.controller + '_' + p.action)}
    render json: {id: @employee.id, permissions: permissions, roles_permissions: roles_permissions}
  end

  def show
    @employee = Employee.unscoped.find(params[:id])
    @emp_pos = @employee.employee_positions
    @employee.languages.create if @employee.languages.blank? #如果没有语言，初始化一个
    @emp_languages = @employee.languages
    @master_position = @emp_pos.find_by(category: '主职').try(:position)

    @audits = @employee.audits.where(status_cd: 1)
  end

  def export_to_xls
    result = parse_query_params!('employee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    get_employees
    @employees = @employees.joins(relations).order(sorts)

    conditions.each do |condition|
      # 进行员工查询
      if condition.first == QuerySetting.employee.new_join_date.sql
        condition[3], condition[4] = condition[1], condition[2]
        @employees = @employees.unscope(:order).order("created_at desc")
      end

      # 参工时间查询特殊处理
      if condition.first == QuerySetting.employee.start_work_date.sql
        condition[3], condition[4] = condition[1], condition[2]
      end

      @employees = @employees.where(condition)
    end

    if params[:employee_ids].present? && !params[:employee_ids].empty?
      @employees = @employees.where("employees.id in (?)", params[:employee_ids].split(','))
    end

    if @employees.present?
      excel = Excel::EmployeeExportor.export(@employees.uniq)
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
      return render text: ''
    end
  end

  def create
    @employee = Employee.new(employee_create_params)

    render json: {messages: "新进员工用工状态不能为离职"}, status: 400 and return if @employee.depart?
    render json: {messages: '岗位不能为空'}, status: 400 and return if position_create_params.count == 0
    render json: {messages: @employee.errors.values.flatten.join(",")}, status: 400 and return unless @employee.valid?

    @employee.employee_presence_columns
    if @employee.errors.present?
      render json: {messages: @employee.errors.values.flatten.join(",")}, status: 400
      return
    end

    emp_pos_error_array = []
    begin
      ActiveRecord::Base.transaction do
        @employee.identity_name = @employee.name.gsub(/[0-9a-zA-Z]/, '')
        @employee.save_without_auditing
        @contact = @employee.contact || @employee.build_contact
        @contact.assign_attributes(contact_params)
        @contact.save_without_auditing
        @employee.create_salary_person_setup!

        # 添加工作餐变动信息
        hash = {employee_id: @employee.id, category: '新进员工'}
        Publisher.broadcast_event('DINNER_CHANGE', hash)

        params[:languages].each do |language|
          emp_language = @employee.languages.build(name: language[:name], grade: language[:grade])
          emp_language.save!
        end

        position_create_params.each do |pos_params|
          emp_pos = @employee.employee_positions.build(pos_params)

          # 这样做确定transaction生效
          (emp_pos_error_array << emp_pos.errors.messages) unless emp_pos.valid?
          emp_pos.save_without_auditing
          emp_pos.generate_work_experience(@employee.join_scal_date, 1)
        end
        new_employee = PermissionGroup.find_by(name: 'new_employee')
        Permission.where("id in (?)", new_employee.permission_ids).each{|permission| permission.grant_permission(@employee)} if new_employee
      end
    rescue ActiveRecord::RecordInvalid => invalid
      emp_pos_error_messages = emp_pos_error_array.inject({}) do |errors, message|
        message.each{ |key, val| errors[key] ? ((errors[key] << val) and errors[key].flatten!.uniq!) : (errors[key] = val)}
        errors
      end
      render json: {messages: emp_pos_error_messages}, status: 400 and return unless emp_pos_error_messages.empty?
    end

    @emp_pos         = @employee.employee_positions.order('sort_index asc').includes(:position)
    @emp_languages   = @employee.languages
    @master_position = @employee.employee_positions.where(category: '主职').first.position
    @employee.fix_sort_no_and_department_id(@master_position.department_id)
    ChangeRecord.save_record('employee_newbie', @employee).send_notification
    ChangeRecordWeb.save_record('employee_newbie', @employee).send_notification

    # 生成本月考勤数据
    department_root_id = @employee.department.parent_chain.first.id
    summary_date = Date.today.strftime("%Y-%m")
    attendance_summary_status_manager = AttendanceSummaryStatusManager.find_by(department_id: department_root_id, summary_date: summary_date)

    unless attendance_summary_status_manager.department_hr_checked
      attendance_summary_status_manager.attendance_summaries.create(
        employee_id: @employee.id,
        employee_name: @employee.name,
        employee_no: @employee.employee_no,
        department_id: @employee.department_id,
        department_name: @employee.department.full_name,
        labor_relation: @employee.labor_relation.display_name,
        summary_date: summary_date
      )
    end

    render template: '/api/employees/show'
  end

  def set_offset_days
    @employee = Employee.find params[:id]
    @employee.set_offset_days(params[:days])
    render json: {messages: '设置成功'}
  end

  # 修改参工时间， 到岗时间， 未在川航工作时间
  def set_employee_date
    @employee = Employee.find params[:id]
    if @employee.present? && @employee.update(
        join_scal_date: params[:join_scal_date],
        start_work_date: params[:start_work_date],
        leave_days: params[:leave_days]
    )
      render json: {messages: '修改成功'}
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

  def update_technical_grade
    @employee = Employee.find params[:id]
    render json: {messages: "请先设置员工薪酬基本设置"}, status: 400 and return if @employee.salary_person_setup.blank?

    item = TechnicalGradeChangeRecord.create(
      employee: @employee,
      technical_grade: params[:technical_grade],
      change_date:     params[:change_date],
      oa_file_no:      params[:oa_file_no]
    )
    item.active_change

    render json: {messages: "记录成功"}
  end

  def update_basic_info
    render text: ''
  end

  def update_skill_info
    render text: ''
  end

  def update_position_info
    render text: ''
  end

  def update
    @employee = Employee.find(params[:id])
    update_params = employee_update_params
    @employee.assign_attributes(update_params)

    render json: {messages: @employee.errors.values.flatten.join(",")}, status: 400 and return unless @employee.valid?
    render json: {messages: '岗位不能为空'}, status: 400 and return if positions_update_params.count == 0
    render json: {messages: '人员主岗位必须为第一个'}, status: 400 and return if positions_update_params.first[:category] != '主职'
    master_position_count = positions_update_params.select{|pos_params| pos_params[:category] == "主职"}.count
    render json: {messages: '人员主岗位不能为空'}, status: 400 and return if master_position_count == 0
    render json: {messages: '人员主岗位只能有一个'}, status: 400 and return if master_position_count == 0

    case params[:edit_type]
    when 'basic'
      @employee.employee_basic_columns
    when 'position'
      @employee.employee_position_columns
    when 'skill'
      
    else
      @employee.employee_presence_columns
    end
    if @employee.errors.present?
      render json: {messages: @employee.errors.values.flatten.join(",")}, status: 400
      return
    end

    emp_pos_error_array = []
    begin
      ActiveRecord::Base.transaction do
        if(@employee.identity_no_changed?)
          hash = {employee_id: @employee.id, category: '身份证变动', indentity_no_was: @employee.identity_no_was}
          Publisher.broadcast_event('SOCIAL_CHANGE_INFO', hash)
        end
        if(@employee.labor_relation_id_changed? and @employee.labor_relation.display_name == '公务员')
          hash = {employee_id: @employee.id, category: '公务员'}
          Publisher.broadcast_event('SOCIAL_CHANGE_INFO', hash)
        end

        #更新员工语言
        if params[:languages].present?
          @employee.languages.destroy_all
          params[:languages].each do |language|
            emp_language = @employee.languages.build(name: language[:name], grade: language[:grade])
            emp_language.save!
          end
        end

        @contact = @employee.contact || @employee.build_contact
        @contact.assign_attributes(contact_params)
        if params[:ignore_audit].to_i == 1
          @employee.save_without_auditing
          @contact.save_without_auditing
        else
          @employee.save
          @contact.save
        end

        @employee_positions = @employee.employee_positions

        # 岗位变动记录到异动中去
        @position_change_record = PositionChangeRecord.new(
          position_form:        positions_update_params,
          employee_id:          @employee.id,
          channel_id:           employee_update_params[:channel_id],
          category_id:          employee_update_params[:category_id],
          oa_file_no:           "无",
          position_change_date: Date.today,
          probation_duration:   0,
          duty_rank_id:         employee_update_params[:duty_rank_id],
          position_remark:      employee_update_params[:position_remark],
          classification:       employee_update_params[:classification],
          location:             employee_update_params[:location],
          operator_name:        @current_employee.name,
          operator_id:          @current_employee.id
        )

        emp_pos_error_array << @position_change_record.errors.messages unless @position_change_record.valid?
        if @position_change_record.check_diff || @position_change_record.check_position_remark
          @position_change_record.save
          @position_change_record.active_change!(params[:ignore_audit].to_i, false, false)
        end
      end
    rescue ActiveRecord::RecordInvalid => invalid
      emp_pos_error_messages = emp_pos_error_array.inject({}) do |errors, message|
        message.each{ |key, val| errors[key] ? ((errors[key] << val) and errors[key].flatten!.uniq!) : (errors[key] = val)}
        errors
      end
      render json: {messages: emp_pos_error_messages}, status: 400 and return unless emp_pos_error_messages.empty?
    end

    @emp_pos = @employee.employee_positions.includes(:position)
    @master_position = @employee.employee_positions.where(category: '主职').first.position
    @emp_languages = @employee.languages

    # 修改员工的考勤汇总数据
    AttendanceSummary.update_summary([@employee])
    ChangeRecord.save_record('employee_update', @employee).send_notification
    ChangeRecordWeb.save_record('employee_update', @employee).send_notification

    render template: '/api/employees/show'
  end

  def show_basic_info
    @employee = Employee.find(params[:id])
    @emp_pos = @employee.employee_positions.order('sort_index asc').includes(:position)
    @master_position = @employee.employee_positions.where(category: '主职').first.position

    render template: '/api/employees/show'
  end

  def show_position_info
    @employee = Employee.find(params[:id])
    @emp_pos = @employee.employee_positions.order('sort_index asc').includes(:position)
    @master_position = @employee.employee_positions.where(category: '主职').first.position

    render template: '/api/employees/show'
  end

  def show_skill_info
    @employee = Employee.find(params[:id])
    @emp_pos = @employee.employee_positions.order('sort_index asc').includes(:position)
    @master_position = @employee.employee_positions.where(category: '主职').first.position

    render template: '/api/employees/show'
  end

  def resume
    @employee = Employee.unscoped.find(params[:id])
    @employee.languages.create if @employee.languages.blank? #如果没有语言，初始化一个
    @languages = @employee.languages
    render template: '/shared/resume'
  end

  def export_resume
    unless params[:employee_id] || params[:employee_ids]
      Notification.send_system_message(current_employee.id, {error_messages: '参数错误'})
      return render text: ''
    end
    resume_service = ExportResumeService.new(params[:employee_id] || params[:employee_ids].split(',')).execute
    send_file(resume_service.path, filename: resume_service.filename)
  end

  def performance_info
    @employee = Employee.find(params[:id])
    @employee.update(performance_info_params)

    render json: {messages: '更新成功'}
  end

  def import
    attachment = Attachment.find(params[:attachment_id])
    importer = Excel::EmployeeImporter.new(attachment.full_path)
    importer.parse_data

    return render json: {messages: importer.errors}, status: 400 if importer.has_errors?
    importer.import

    render json: {messages: '导入成功'}
  end

  def import_family_members
    attachment = Attachment.find_by(id: params[:attachment_id])
    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      message = Excel::FamilyMemberImportor.import(attachment.file.url)
      render json: message
    end
  end

  def family_members
    employee = Employee.find(params[:id])
    @family_members = employee.family_members.where(relation: params["relation"])

    render json: {family_members: @family_members}
  end

  def attendance_records
    beginning_of_year = Date.today.beginning_of_year
    end_of_year = Date.today.end_of_year
    @employee = Employee.find(params[:id])

    attendances = @employee.attendances.where("(record_date >= ?) AND (record_date <= ?)", beginning_of_year, end_of_year)
    @late_or_early_leaves = attendances.late_or_early_leave
    @flight_groundeds     = attendances.flight_grounded
    @flight_ground_works  = attendances.flight_ground_work
    @absences = attendances.absence
    @leaves   = @employee.own_flows.leaves.actived.where("(updated_at >= ?) AND (updated_at <= ?)", beginning_of_year, end_of_year)

    render template: '/api/me/me/attendance_records'
  end

  def set_leave
    hash = params.permit(:file_no, :reason, :date)
    return render json: {messages: '离职时间选择不能大于今天的日期'}, status: 400 if hash[:date].to_date > Date.today

    Publisher.broadcast_event('EMPLOYEE_LEAVE', hash.merge(employee_id: params[:id]))
    render json: {messages: '离职创建成功'}
  end

  def set_early_retire
    hash = params.permit(:file_no, :date)
    if hash[:file_no].blank?
      render json: {messages: '文件号不能为空'}, status: 400 and return
    elsif hash[:date].to_date > Date.today
      render json: {messages: '退养时间选择不能大于今天的日期'}, status: 400 and return
    end

    Publisher.broadcast_event('EMPLOYEE_EARLY_RETIRE', hash.merge(employee_id: params[:id]))
    render json: {messages: '退养创建成功'}
  end

  def transfer_to_regular_worker
    attachment = Attachment.find(params[:attachment_id])
    regular_worker_importer = Excel::RegularWorkerImporter.new(attachment.full_path)

    if regular_worker_importer.parse_data && regular_worker_importer.valid?
      regular_worker_importer.import
      render json: {messages: '批量转正成功'}
    else
      render json: {messages: regular_worker_importer.errors}, status: 400
    end
  end

  def change_technical
    employee = Employee.find(params[:id])
    technical_record = employee.technical_records.new(params.permit(:technical, :file_no, :change_date))

    if technical_record.save
      ChangeRecordWeb.save_record('employee_update', employee).send_notification
      render json: {messages: '技术等级变更成功'}
    else
      render json: {messages: '技术等级变更失败'}, status: 400
    end
  end

  def technical_records
    employee = Employee.find(params[:id])
    @technical_records = employee.technical_records

    render json: {technical_records: @technical_records}
  end

  def work_experience_import
    attachment = Attachment.find_by(id: params[:attachment_id])
    if attachment.nil?
      return render json: {messages:"导入失败"}, status: 400
    end
    full_path = attachment.full_path
    importer = Excel::WorkExperienceImport.new(full_path)
    importer.parse_data
    if importer.errors.present?
      return render json: {messages:importer.errors}, status: 400
    else
      begin
        importer.import
      rescue
      end
      if importer.errors.present?
        return render json: {messages:importer.errors}, status: 400
      else
        render json: {messages:"导入成功"}
      end
    end
  end

  def star_import
    attachment = Attachment.find_by(id: params[:attachment_id])
    if attachment.nil?
      return render json: {messages:"导入失败"}, status: 400
    end
    full_path = attachment.full_path
    importer = Excel::EmployeeStarImportor.new(full_path)
    importer.vaild_format
    if importer.errors.present?
      return render json: {messages:importer.errors}, status: 400
    else
      begin
        importer.import
      rescue
      end
      if importer.errors.present?
        return render json: {messages:importer.errors}, status: 400
      else
        render json: {messages:"导入成功"}
      end
    end
  end

  private
  def performance_info_params
    params.permit(:month_distribute_base, :pcategory)
  end

  def employee_create_params
    safe_attributes = employee_attr
    safe_params(safe_attributes)
  end

  def basic_info_params
    params.permit(
      :name, :gender_id, :identity_no, :political_status_id, :start_work_date,
      :join_scal_date, :start_internship_date, :probation_months, :english_level_id,
      :school, :major, :education_background_id, :degree_id, :graduate_date,
      :classification
    )
  end

  def education_info_params
    params.permit(:education_background_id, :degree_id, :graduate_date, :school, :major, :change_education_date)
  end

  def position_info_params
    params.permit(
      :category_id, :channel_id, :duty_rank_id, :labor_relation_id,
      :employment_status_id, :location, :position_remark
    )
  end

  def skill_info_params
    params.permit(:job_title, :job_title_degree_id, :technical_duty)
  end

  def employee_update_params
    attributes = employee_attr

    attributes.delete(:employment_status_id)
    attributes.delete(:employee_no) # 暂时不支持employee_no的更改，需求未确定
    safe_params(attributes)
  end

  def employee_attr
    [
      :name, :employee_no, :gender_id, :identity_no, :political_status_id,\
      :education_background_id, :duty_rank_id, :degree_id, :graduate_date,\
      :school, :major, :english_level_id, :location,\
      :labor_relation_id, :position_remark, :employment_status_id,\
      :job_title_degree_id, :job_title, :join_scal_date, :probation_months,\
      :start_work_date, :technical_duty, :channel_id, :category_id, :birthday,\
      :native_place, :start_internship_date, :classification, :nation, :nationality
    ]
  end

  def contact_params
    params[:contact] ? params.require(:contact).permit(:mobile, :mailing_address, :address, :postcode, :telephone, :email) : {}
  end

  def position_create_params
    handled_pos_params = []
    return handled_pos_params  if params[:position].blank?

    handled_pos_params << {
      position_id: params[:position][:id],
      category: "主职",
      sort_index: "0"
    }
    handled_pos_params
  end

  def positions_update_params
    handled_pos_params = []
    return handled_pos_params  if params[:positions].blank?

    params[:positions].each_with_index do |pos_params, index|
      handled_pos_params << {
        position_id: pos_params[:position][:id],
        category: pos_params[:category],
        sort_index: "#{index}"
      } if pos_params && pos_params[:position]
    end
    handled_pos_params
  end

  def get_assign_department dep
    if dep.serial_number.length <= 6
      dep
    elsif dep.serial_number.length > 6
      get_assign_department(dep.parent)
    else
      nil
    end
  end

  def get_employees
    @employees = Employee.includes(
      [
        :job_title_degree, :political_status, :education_background,\
        :contact, :master_positions, :category, :department,\
        :offset_days_record, :employee_positions, :languages,\
        :positions => [:department],
      ]
    ).joins(
      "JOIN departments ON departments.id = employees.department_id"
    ).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    )

    if !(@current_employee.hr? and !@current_employee.department_hr?) and !@current_employee.company_leader?
      department_ids = @current_employee.get_departments_for_role

      if department_ids.present?
        @employees = @employees.joins(:positions)
          .where("positions.department_id in (?) or employees.id = #{@current_employee.id}", department_ids)
      else
        @employees = @employees.joins(:positions).where("employees.id = #{@current_employee.id}")
      end
    end
  end
end
