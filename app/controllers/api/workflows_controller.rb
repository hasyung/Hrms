class Api::WorkflowsController < ApplicationController
  include FlowSafeAttributes
  skip_before_action :check_action_register
  skip_before_action :check_permission
  before_action :intercept_event_to_close_state, only: [:update]
  before_action :check_reviewer, only: [:create, :update], unless: :skip_check_reviewer?
  
  def create
    create_concern
  end

  def proxy_for_leave
    create_concern
  end

  def batch_create
    if Flow.batch_create_types.exclude?(params[:flow_type])
      return render json: {messages: '此流程不可以批量创建'}, status: 400
    end

    clazz = params[:flow_type].constantize
    unless Rails.env.test?
      if clazz.respond_to?(:initiator) && !clazz.initiator(initiator_params)
        return render json: {messages: '权限错误'}, status: 400
      end
    end

    @workflows = params[:receptors].inject([]) do |arr, receptor|
      if Flow.employee_filter_types.include?(params[:flow_type]) && clazz.where("workflow_state in (?)",
        Flow.employee_filter_states).find_by(receptor_id: receptor["id"]).present?
        return render json: {messages: '该员工已发起过此流程'}, status: 400
      end
      flow = CreateFlowService.new(batch_service_params(receptor))
      if flow.valid?
        arr << flow.call
      else
        return render json: {messages: flow.error_messages}, status: 400
      end

    end
    build_view_by_flow_type
  end

  def supplement
    @workflow = Flow.find(params[:id])
    if @workflow.receptor_id != current_employee.id && !@workflow.can_supplement?
      return render json: {messages: '权限错误'}, status: 400
    end

    attachments = FlowAttachment.where(id: params[:attachment_ids])
    if attachments.blank?
      return render json: {messages: '参数错误'}, status: 400
    else
      attachments.update_all(flow_id: @workflow.id)
    end

    @events = @workflow.flow_nodes
    render template: '/api/workflows/show'
  end

  def transfer_to_occupation_injury
    @flow = Flow.find(params[:id])

    return render json: {messages: '只有工伤待定才能转工伤'}, status: 400 if @flow.type != 'Flow::SickLeaveInjury'

    @adjust_leave_type_service = AdjustLeaveTypeService.new(@flow, "Flow::OccupationInjury")

    if @adjust_leave_type_service.can_adjust?
      @adjust_leave_type_service.adjust

      render json: {messages: '转假成功'}
    else
      render json: {messages: '已经考勤汇总确认不能够再进行假别调整'}, status: 400
    end
  end

  def node_create
    current_flow = Flow.find(params[:id])
    update_service_params = service_params.merge!(body: params[:body], flow: current_flow)

    if !current_flow.reviewer_ids.flatten.include?(current_employee.id) && params[:flow_type] != 'Flow::RenewContract'
      return render json: {messages: '权限错误'}, status: 400
    end
    return render json: {messages: '参数错误'}, status: 400 if update_service_params[:body].blank?

    node = UpdateFlowService.new(update_service_params).create_workflow_event
    if node.blank?
      render json: {messages: '参数错误'}, status: 400
    else
      render json: {flow_node: node}
    end
  end

  def node_update
    node = WorkflowEvent.find(params[:node_id])
    if node.reviewer_id != current_employee.id && params[:flow_type] != 'Flow::RenewContract'
      return render json: {messages: '权限错误'}, status: 400
    end
    return render json: {messages: '参数错误'}, status: 400 if params[:body].blank?

    if node.update(params.permit(:body))
      render json: {flow_node: node}
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

  def attachments
    @attachment = FlowAttachment.new params.permit(:file)

    if @attachment.save
      render template: '/api/workflows/attachment'
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

  def repeal #撤销请假
    @flow = Flow.find(params[:id])

    return render json: {messages: "流程已经结束"}, status: 400 if %w(rejected actived repeal).include?(@flow.workflow_state)

    if @flow.receptor_id != @current_employee.id && Flow.department_hr(@flow.receptor.department_id).exclude?(@current_employee.id) && 
      !(@flow.receptor_id != @flow.sponsor_id && @flow.sponsor_id == @current_employee.id)
      return render json: {messages: '权限错误'}, status: 400
    end
    reviewer_id = @flow.viewer_ids

    viewer_ids = []
    if @flow.reviewer_ids.blank?
      viewer_ids = @flow.viewer_ids - [@flow.sponsor_id]
    else
      viewer_ids = @flow.viewer_ids - @flow.reviewer_ids - [@flow.sponsor_id]
    end
    name = Employee.unscoped.find(@flow.receptor_id).name
    #@flow.viewer_ids |= @flow.reviewer_ids
    viewer_ids = viewer_ids.uniq
    viewer_ids.each do |employee_id|
      Notification.send_user_message employee_id,params[:flow_type],"#{name}的#{@flow.name}申请已撤销"
    end if viewer_ids.present?
    
    @flow.reviewer_ids = []
    @flow.workflow_state = 'repeal'
    if @flow.save
      render json: {workflow: @flow}
    else
      render json: {messages: @flow.errors.values.flatten.join(",")}, status: 400
    end
  end

  def deduct #年假/补休假 抵扣
    @flow = Flow.find(params[:id])
    @flow.receptor_id != current_employee.id and return render json: {messages: '权限错误'}, status: 400

    deduct_days = params[:days]
    vacation_days = @flow.vacation_days
    return render json: {messages: '必须填写抵扣天数'} if !deduct_days

    !%w(Flow::SickLeave Flow::PersonalLeave).include?(params[:flow_type]) and return render json: {messages: '只有事假和病假支持抵扣'}, status: 400
    !@flow.can_deduct? and return render json: {messages: '不能重复发起假期抵扣'}, status: 400

    @flow.start_time.to_datetime.advance(months: 2) < DateTime.now and return render json: {messages: '假期抵扣只支持2个月以内的事假和病假'}, status: 400

    if params[:deduct_type] == 'annual'
      deduct_days > current_employee.total_year_days and return\
        render json: {messages: '你剩余的年假不足抵扣！'}, status: 400
    elsif params[:deduct_type] == 'offset'
      deduct_days > current_employee.offset_days and return\
        render json: {messages: '你剩余的补休假不足抵扣!'}, status: 400
    else
      render json: {messages: '参数错误'} and return
    end

    days = deduct_days >= vacation_days ? vacation_days : deduct_days
    if params[:deduct_type] == 'annual'
      @flow.update(name: "#{@flow.name}-年假抵扣", vacation_days: "#{vacation_days}-#{days}", is_adjusted: true)
      current_employee.reduce_year_days(days) #扣除年假
    else
      @flow.update(name: "#{@flow.name}-补休假抵扣", vacation_days: "#{vacation_days}-#{days}", is_adjusted: true)
      current_employee.reduce_offset_days(days) #扣除补休假
    end

    # 扣减考勤汇总
    # 计算方式是从开始日期的考勤汇总开始算起
    records = @flow.leave_date_record
    receptor = @flow.receptor

    if vacation_days == days
      leave_type = params[:deduct_type] == 'annual' ? "Flow::AnnualLeave" : "Flow::OffsetLeave"
      deduct_leave_date = records.inject({}) do |result, (month, value)|

        attendance_summary = receptor.attendance_summaries.find_by(summary_date: month)
        result[month] = {
          "start_time"    => value["start_time"],
          "end_time"      => value["end_time"],
          "vacation_days" => value["vacation_days"],
          "leave_type"    => leave_type
        }

        AttendanceCalculator.change_leave_days(
          {
            ex_type: value["leave_type"],
            ex_vacation_days: value["vacation_days"],
            type: leave_type,
            vacation_days: value["vacation_days"],
            start_time: value["start_time"],
            end_time: value["end_time"]
          },
          receptor,
          attendance_summary,
          true, true
        ) if attendance_summary

        result
      end

      @flow.update(deduct_leave_date: deduct_leave_date, leave_date_record: {})
    else
      count_days = days
      new_start_time = ""
      leave_vacation_days = 0

      leave_type = params[:deduct_type] == 'annual' ? "Flow::AnnualLeave" : "Flow::OffsetLeave"

      deduct_leave_date = records.inject({}) do |result, (month, value)|
        if count_days != 0
          attendance_summary = receptor.attendance_summaries.find_by(summary_date: month)

          if count_days >= value["vacation_days"]
            result[month] = {
              "start_time"    => value["start_time"],
              "end_time"      => value["end_time"],
              "vacation_days" => value["vacation_days"],
              "leave_type"    => leave_type
            }
            count_days  = count_days - value["vacation_days"]
            reduce_days = vacation_days["vacation_days"]
          else
            # 判断是不是有半天的问题
            if count_days != count_days.to_i
              if value["start_time"] =~ /T13:/
                deduct_end_time = value["start_time"].to_date.advance(days: count_days).to_s + "T#{Setting.daily_working_hours.afternoon_end}+08:00"
                result[month] = {
                  "start_time"    => value["start_time"],
                  "end_time"      => deduct_end_time,
                  "vacation_days" => count_days,
                  "leave_type"    => leave_type
                }
                new_start_time = value["start_time"].to_date.advance(days: count_days + 1).to_s + "T#{Setting.daily_working_hours.morning}+08:00"
              else
                new_start_time = deduct_end_time = value["start_time"].to_date.advance(days: count_days).to_s + "T#{Setting.daily_working_hours.afternoon}+08:00"
                result[month] = {
                  "start_time"    => value["start_time"],
                  "end_time"      => deduct_end_time,
                  "vacation_days" => count_days,
                  "leave_type"    => leave_type
                }
              end
            else
              if value["start_time"] =~ /T13:/
                new_start_time = deduct_end_time = value["start_time"].to_date.advance(days: count_days).to_s + "T#{Setting.daily_working_hours.afternoon}+08:00"
                result[month] = {
                  "start_time"    => value["start_time"],
                  "end_time"      => deduct_end_time,
                  "vacation_days" => count_days,
                  "leave_type"    => leave_type
                }
              else
                deduct_end_time = value["start_time"].to_date.advance(days: count_days - 1).to_s + "T#{Setting.daily_working_hours.afternoon_end}+08:00"
                result[month] = {
                  "start_time"    => value["start_time"],
                  "end_time"      => deduct_end_time,
                  "vacation_days" => count_days,
                  "leave_type"    => leave_type
                }
                new_start_time = value["start_time"].to_date.advance(days: count_days).to_s + "T#{Setting.daily_working_hours.morning}+08:00"
              end
            end

            leave_vacation_days = value["vacation_days"] - count_days
            reduce_days = count_days
            count_days = 0
          end

          AttendanceCalculator.change_leave_days(
            {
              ex_type: value["leave_type"],
              ex_vacation_days: reduce_days,
              type: leave_type,
              vacation_days: reduce_days,
              start_time: value["start_time"],
              end_time: value["end_time"]
            },
            receptor,
            attendance_summary,
            true, true
          ) if attendance_summary
        end

        result
      end

      deduct_keys = deduct_leave_date.keys
      new_leave_date_records = records.inject({}) do |result, (month, value)|
        unless deduct_keys.include?(month)
          result[month] = value
        end

        if deduct_keys.last == month
          result[month] = {
            "start_time"    => new_start_time,
            "end_time"      => value["end_time"],
            "leave_type"    => value["leave_type"],
            "vacation_days" => leave_vacation_days
          }
        end

        result
      end

      @flow.update(leave_date_record: new_leave_date_records, deduct_leave_date: deduct_leave_date)
    end

    render json: {workflow: @flow}
  end

  def update
    update_service_params = service_params.merge!(opinion: params[:opinion], flow: @flow)
    if !@flow.reviewer_ids.flatten.include?(current_employee.id) && params[:flow_type] != 'Flow::RenewContract'
      return render json: {messages: '权限错误'}, status: 400
    end

    @workflow = UpdateFlowService.new(update_service_params).call
    render json: {workflow: @workflow}
  end

  def index
    if params[:flow_type].blank?  #所有类型待处理流程数量
      render json: {workflows: Flow.get_user_workflow_messages_by_employee(@current_employee)}
    else
      result = parse_query_params!('flow')
      render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
      relations, conditions, sorts, page = result.values

      if params[:flow_type] == 'leave'
        @workflows = Flow.includes(:flow_nodes).where("type in (?)", Flow.leave_types)
          .where("reviewer_ids like '%- #{@current_employee.id}\n%'").joins(relations).order(sorts)
        conditions.each do |condition|
          @workflows = @workflows.where(condition)
        end
        @workflows = set_page_meta @workflows, page
        render template: '/api/workflows/leave'
      else  #单个类型待处理列表
        @workflows = Flow.includes(:flow_nodes).where(type: params[:flow_type]).
          where("reviewer_ids like '%- #{@current_employee.id}\n%'").joins(relations).order(sorts)
        conditions.each do |condition|
          @workflows = @workflows.where(condition)
        end
        @workflows = set_page_meta @workflows, page
        build_view_by_flow_type
      end
    end
  end

  #单个类型历史记录
  def record
    if params[:state]
      arr = []
      params[:state].each do |state_id|
        arr << CodeTable::WorkflowState.find_by(id:state_id).name
      end
      params[:workflow_states] = arr
    end
    
    result = parse_query_params!('flow')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    # 针对查询form_data中的leave_job_state,需要格式化下form_data的sql语句
    conditions = conditions.inject([]) do |conds, cond|
      if cond.first =~ /^leave_job_state/
        key = cond.first.sub("leave_job_state", "form_data")
        val = cond.last.gsub("%", "")
        conds << [key, "%\nleave_job_state: #{val}\n%"]
      else
        conds << cond
      end

      conds
    end

    if params[:flow_type] == 'leave'
      @workflows = Flow.includes(:flow_nodes).where("flows.type in (?)", Flow.leave_types).joins(relations).order(sorts)

      if !@current_employee.hr_labor_relation_member? && @current_employee.name != 'administrator'
        department_ids = @current_employee.get_departments_for_role
        if department_ids.present?
          # 由于在joins的时候recptor如果有多条employee_positions
          # 那么就会存在流程出现多条重复的情况
          @workflows = @workflows.joins(receptor: [:positions])
            .where("positions.department_id in (?) or flows.viewer_ids like '%- #{@current_employee.id}\n%'",
            department_ids).uniq
        else
          @workflows = @workflows.where("flows.viewer_ids like '%- #{@current_employee.id}\n%'")
        end
      end

      conditions.each do |condition|
        @workflows = @workflows.where(condition)
      end
      @workflows = set_page_meta @workflows, page
      render template: '/api/workflows/leave'
    else
      @workflows = Flow.includes(:flow_nodes).where(type: params[:flow_type]).joins(relations).order(sorts)
      if params[:flow_type] != 'Flow::Retirement' || !@current_employee.hr_labor_relation_member?
        deps = FlowRelation.get_deps_department_hr(@current_employee)
        if params[:flow_type] != 'Flow::Resignation' || deps.blank?
          @workflows = @workflows.where("viewer_ids like '%- #{@current_employee.id}\n%'")
        else
          @workflows = @workflows.joins(receptor: :department).where("flows.viewer_ids like
            '%- #{@current_employee.id}\n%' or departments.id in (?)", deps)
        end
      end
      conditions.each do |condition|
        @workflows = @workflows.where(condition)
      end
      @workflows = set_page_meta @workflows, page
      build_view_by_flow_type
    end
  end

  def show
    @workflow = Flow.find(params[:id])
  end

  def single_record
    @workflow = Flow.find(params[:id])

    render template: '/api/workflows/leave_record'
  end

  def adjust_leave_type
    # 部门HR专员修改本部门的员工请假类别
    @workflow = Flow.find(params[:id])

    return render json: {messages: '该请假记录还未生效无法进行假别调整'}, status: 400 if @workflow.workflow_state != 'actived'
    return render json: {messages: '发生了抵扣的流程不能调整假别'}, status: 400 if @workflow.is_deducted
    return render json: {messages: '发生了假别变更的流程不能再调整假别'}, status: 400 if @workflow.is_adjusted

    @adjust_leave_type_service = AdjustLeaveTypeService.new(@workflow, params[:type])

    if @adjust_leave_type_service.can_adjust?
      @adjust_leave_type_service.adjust

      render json: {messages: '假别修改成功'}
    else
      render json: {messages: '已经考勤汇总确认不能够再进行假别调整'}, status: 400
    end
  end

  #假期录入
  def instead_leave
    start_time = ''
    end_time = ''
    if params[:start_time].include?(Setting.daily_working_hours.morning) || params[:start_time].include?(Setting.daily_working_hours.afternoon)
      start_time = params[:start_time]
    else
      if params[:start_time] =~ /00:00:00/
        start_time = params[:start_time].sub("T00:00:00", "T#{Setting.daily_working_hours.morning}")
      else
        start_time = (Time.parse(params[:start_time]) + 8.hours).strftime("%Y-%m-%dT%H:%M:00")
      end
    end
    if params[:end_time].include?(Setting.daily_working_hours.afternoon) || params[:start_time].include?(Setting.daily_working_hours.afternoon_end)
      end_time = params[:end_time]
    else
      if params[:end_time] =~ /00:00:00/
        end_time = params[:end_time].sub("T00:00:00", "T#{Setting.daily_working_hours.afternoon_end}")
      else
        end_time = (Time.parse(params[:end_time]) + 8.hours).strftime("%Y-%m-%dT%H:%M:00")
      end
    end

    vacation_days = VacationRecord.cals_days(
        employee_id: params[:receptor_id],
        start_date: start_time.to_datetime.beginning_of_day.to_date,
        end_date: end_time.to_datetime.beginning_of_day.to_date,
        start_time: DateTime.iso8601(start_time.to_datetime.strftime("%Y-%m-%dT%H:%M:00")+"+08:00"),
        end_time: DateTime.iso8601(end_time.to_datetime.strftime("%Y-%m-%dT%H:%M:00")+"+08:00"),
        vacation_type: I18n.t("flow.type.#{params[:type]}")
    )[:general_days]

    condition = {
      :flow_type => params[:type],
      :flow_params => {
        "start_time" => start_time,
        "end_time" => end_time,
        "reason" => params[:reason],
        "vacation_days" => vacation_days,
        "receptor_id" => params[:receptor_id],
        "attachment_ids" => params[:attachment_ids],
        "relation_data" => params[:relation_data]
      },
      :current_user => current_employee,
      :reviewer_ids => nil      
    }

    condition[:flow_params].merge!({"relation" => params[:relation],"journey" => params[:journey]}) if params[:type] == "Flow::FuneralLeave" ||  params[:type] == "Flow::HomeLeave"
    condition[:flow_params].merge!({"during_pregnancy" => params[:during_pregnancy]}) if params[:type] == "Flow::MiscarriageLeave" || params[:type] == "Flow::PrenatalCheckLeave"
    condition[:flow_params].merge!({"marriage_time" => params[:marriage_time]}) if params[:type] == "Flow::MarriageLeave"
    
    flow = CreateFlowService.new(condition)
    employee = Employee.find(condition[:flow_params]["receptor_id"])
    unless flow.valid?
      return render json: {messages: "#{employee.employee_no} #{employee.name},#{flow.error_messages}"}, status: 400
    end
    time_now = Time.now
   
    workflow = flow.call
    flows = Flow.find(workflow.id)

    if condition[:flow_params]["start_time"].to_date < time_now
      flows.active_workflow
    else
      flows.workflow_state = "accepted"
    end
    flows.save
    return render json: {messages: "录入成功"}
  end

  # 针对客舱部门
  def vacation_distribute_list
    if params[:month].nil?
      return render json: {workflows:[]}
    end
    result = parse_query_params!('cabin_vacation_imports')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values
    @cvis = CabinVacationImport.where(is_checking:0, sponsor_id:current_employee.id, import_month:params[:month])
    conditions.each do |condition|
      @cvis = @cvis.where(condition)
    end
    page = {page: params[:page], per_page: params[:per_page]}
    @cvis = set_page_meta @cvis, page
    render template: '/api/workflows/vacation_distribute_list'
  end

  #导入请假单
  def cabin_vacation_import
    cabin_vacation_imports = CabinVacationImport.where(sponsor_id:current_employee.id,is_checking:0,import_month:params[:month])
    cabin_vacation_imports.each do |cabin|
      cabin_vacation_imports.destroy(cabin.id)
    end
    attachment = Attachment.find(params[:attachment_id])
    cabin_leave_importer = Excel::CabinLeaveImporter.new(attachment.full_path, @current_employee, params[:month]).read_excel
    if cabin_leave_importer.errors.present?
      render json: {messages: cabin_leave_importer.errors}, status: 400
      return
    end

    result = cabin_leave_importer.import

    unless result
      render json: {messages: cabin_leave_importer.errors}, status: 400
      return
    end

    render json: {messages: '导入成功'}
  end

  #审批导入的请假
  def approve_vacation_list
    cabin_imports = CabinVacationImport.where(sponsor_id:current_employee.id, is_checking:0, import_month:params[:month])
    return render json:{message:""} if cabin_imports.empty?
    service_params_arr = []
    cabin_imports.each do |cabin_import|
      service_params = {
        :flow_type => (I18n.t("flow.type").invert)[cabin_import.leave_type],
        :flow_params => {
          "start_time" => cabin_import.start_leave_date,
          "end_time" => cabin_import.end_leave_date,
          "reason" => "",
          "vacation_days" => cabin_import.vacation_days,
          "receptor_id" => cabin_import.employee_id,
          "attachment_ids" => nil,
          "relation_data" => nil
        },
        :current_user => current_employee,
        :reviewer_ids => nil      
      }
      service_params_arr << service_params
    end
    annual_index = 1
    service_params_arr.each do |service_params|
      
      flow = CreateFlowService.new(service_params)
      employee = Employee.find(service_params[:flow_params]["receptor_id"])
      unless flow.valid?
        return render json: {messages: "#{employee.employee_no} #{employee.name},#{flow.error_messages}"}, status: 400
      end

      #已生效的年假扣除剩余年假天数
      time_now = Time.now
      if service_params[:flow_params]["start_time"].to_date < time_now && service_params[:flow_type] == "Flow::AnnualLeave"
        if annual_index == 1
          vacation_days = 0
          VacationRecord.where(employee_id:service_params[:flow_params]["receptor_id"], record_type: "年假").each do |vacation_day|
            vacation_days = vacation_days + vacation_day.days
          end
          if vacation_days < service_params[:flow_params]["vacation_days"]
            return render json: {messages: "#{employee.name}年假天数不足！"}, status: 400
          end
        end
        reduce_bool = VacationRecord.reduce_days service_params[:flow_params]["receptor_id"], service_params[:flow_params]["start_time"].to_date.strftime("%Y"), service_params[:flow_params]["vacation_days"]
        return render json: {messages: "#{employee.name}年假天数不足！"} unless reduce_bool
        annual_index += 1
      end
      
      workflow = flow.call
      flows = Flow.find(workflow.id)


      if service_params[:flow_params]["start_time"].to_date < time_now
        flows.active_workflow
      else
        flows.workflow_state = "accepted"
      end
      flows.save
      update_flow_params ={
        :body => "同意",
        :current_user => current_employee,
        :flow => flows
      }
      UpdateFlowService.new(update_flow_params).create_workflow_event
    end
    cabin_imports.each do |cabin|
      CabinVacationImport.update(cabin.id,is_checking:1)
    end
    return render json: {messages: "审批成功"}
  end

  private
  def flow_create_attributes
    params.permit(*safe_flow_attributes(params["flow_type"])).merge!({
      receptor_id: params["receptor_id"] || current_employee.id,
      attachment_ids: params["attachment_ids"],
      relation_data: params["relation_data"]
    })
  end

  def service_params(flow_attributes = nil)
    reviewer_ids = Flow.file_managers(params[:department_ids]) if params[:department_ids]
    reviewer_ids = [params[:reviewer_id]] if params[:reviewer_id]
    reviewer_ids = [params[:receptor_id]] if params[:flow_type] == 'Flow::RenewContract' && params[:action] == 'create'

    {
      flow_type: params[:flow_type],
      flow_params: flow_attributes,
      current_user: current_employee,
      reviewer_ids: reviewer_ids || []
    }
  end

  def batch_service_params(receptor)
    flow_attributes = params.permit(*safe_flow_attributes(params["flow_type"])).merge!({
      receptor_id: receptor["id"],
      relation_data: receptor["relation_data"],
      retirement_date: receptor["retirement_date"]
    })
    reviewer_ids = Flow.file_manager(Employee.find_by(id: receptor["id"].to_i).try(:department_id)) if params[:flow_type] == 'Flow::Retirement'
    {
      flow_type: params[:flow_type],
      flow_params: flow_attributes,
      current_user: current_employee,
      reviewer_ids: reviewer_ids || []
    }
  end

  def intercept_event_to_close_state
    @flow = Flow.find(params[:id])

    if @flow.flow_end?
      render json: {messages: "该流程已经结束"}, status: 400 and return
    end
  end

  def initiator_params
    receptor_id = params["receptor_id"] || current_employee.id
    {
      sponsor_id: current_employee.id,
      receptor_id: receptor_id.to_i
    }
  end

  def check_reviewer
    # opnion为空说明领导没有点同意或拒绝，所以必须要上传reviewer_id或department_ids
    # 当create的时候opinion为空;
    return if params[:flow_type] == 'Flow::RenewContract'

    if params[:opinion].nil? && !(params[:reviewer_id] || params[:department_ids])
      render json: {messages: '没有选择下步审批人或机构'}, status: 400 and return
    end
  end

  def skip_check_reviewer?
    (params[:flow_type] == "Flow::EmployeeLeaveJob" && action_name == "create")
  end

  def create_concern
    clazz = params[:flow_type].constantize
    if params[:flow_type] == 'Flow::EmployeeLeaveJob' &&
      (params["receptor_id"].blank? || Employee.find_by(id: params["receptor_id"]).blank?)
      return render json: {messages: '未找到主体人'}, status: 400
    end

    # 客舱服务部下面分类为员工，通道为空乘的不能通过这里请年假
    employee = Employee.find_by(id: params["receptor_id"])
    if ["Flow::AnnualLeave", "Flow::RecuperateLeave"].include?(params[:flow_typee]) && employee.department.name == "客舱服务部" &&
      employee.category.display_name == "员工" && employee.channel.display_name == "空乘"
      return render json: {messages: "客舱服务部下分类为员工通道为空乘的人员不能请年假"}, status: 400
    end

    unless Rails.env.test?
      if clazz.respond_to?(:initiator) && !clazz.initiator(initiator_params)
        return render json: {messages: '权限错误'}, status: 400
      end
    end

    if Flow.employee_filter_types.include?(params[:flow_type]) && clazz.where("workflow_state in (?)",
      Flow.employee_filter_states).find_by(receptor_id: params["receptor_id"] || current_employee.id).present?
      return render json: {messages: '该员工已发起过此流程'}, status: 400
    end

    @flow = CreateFlowService.new(service_params(flow_create_attributes))
    if @flow.valid?
      @workflow = @flow.call
      render json: {messages: "创建成功"}
    else
      render json: {messages: @flow.error_messages}, status: 400
    end
  end

  def build_view_by_flow_type
    case params[:flow_type]
    when 'Flow::EarlyRetirement'
      render template: '/api/workflows/retirement'
    when 'Flow::AdjustPosition'
      render template: '/api/workflows/adjust_position'
    when 'Flow::EmployeeLeaveJob'
      render template: '/api/workflows/punishment'
    when 'Flow::Resignation'
      render template: '/api/workflows/resignation'
    when 'Flow::Retirement'
      render template: '/api/workflows/retirement'
    when 'Flow::Punishment'
      render template: '/api/workflows/punishment'
    when 'Flow::Dismiss'
      render template: '/api/workflows/resignation'
    when 'Flow::RenewContract'
      render template: '/api/workflows/renew_contract'
    else
      render template: '/api/workflows/index'
    end
  end
end
