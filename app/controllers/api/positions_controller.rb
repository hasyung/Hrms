class Api::PositionsController < ApplicationController
  include ExceptionHandler

  def index
    if params[:department_id]
      @positions = Position.includes(:channel, :employees, :employee_positions, :schedule, :category, :department, :position_nature).where(department_id: params[:department_id]).order(:sort_no)
      page = parse_query_params!("position").values.last

      if !(@current_employee.hr? and !@current_employee.department_hr?) and !@current_employee.company_leader?
        department_ids = @current_employee.get_departments_for_role
        if department_ids.present?
          @positions = @positions.joins(:employees).where(
            "positions.department_id in (?) or employees.id = #{@current_employee.id}", department_ids)
        else
          @positions = @positions.joins(:employees).where("employees.id = #{@current_employee.id}")
        end
      end

      @department_positions = set_page_meta(@positions, page)
    else
      result = parse_query_params!('position')
      render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
      relations, conditions, sorts, page = result.values

      @positions = Position.not_confirmed.joins(
        "JOIN departments ON positions.department_id = departments.id"
      ).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, positions.sort_no"
      ).joins(relations).order(sorts).preload(
        [:channel, :employees, :employee_positions, :schedule, :category, :department, :position_nature]
      )

      if !(@current_employee.hr? and !@current_employee.department_hr?) and !@current_employee.company_leader?
        department_ids = @current_employee.get_departments_for_role
        if department_ids.present?
          @positions = @positions.joins(:employees).where(
            "positions.department_id in (?) or employees.id = #{@current_employee.id}", department_ids)
        else
          @positions = @positions.joins(:employees).where("employees.id = #{@current_employee.id}")
        end
      end

      conditions.each do |condition|
        @positions = @positions.where(condition)
      end

      @positions = set_page_meta @positions.uniq, page
    end
  end

  def show
    @position = Position.find(params[:id])
  end

  def create
    return render json: {messages: "机构不存在或未生效"}, status: 400 if Department.where(id: position_params[:department_id]).empty?
    @position = Position.new(position_params)
    @position.fix_sort_no

    if @position.save
      ChangeRecordWeb.save_record("position_create", @position).send_notification
      render template: '/api/positions/show'
    else
      render json: {messages: @position.errors.values.flatten.join(",")}, status: 400
    end
  end

  def update
    @position = Position.find(params[:id])

    if @position.update(position_params)
      audit = @position.audits.last
      audit.update(audited_changes: audit.audited_changes.delete_if{|a|a == 'staffing_remark'}, remark: position_params[:staffing_remark]) if audit
      ChangeRecordWeb.save_record("position_update", @position).send_notification
      render template: '/api/positions/show'
    else
      render json: {messages: @position.errors.values.flatten.join(",")}, status: 400
    end
  end

  def batch_destroy
    @positions = Position.where(id: params[:ids])

    render json: {messages: '没有选中岗位'} and return if @positions.empty?

    if @positions.can_destroy?
      Position.transaction do
        Audit.create_with_positions(@positions, @current_employee)
        Specification.where("position_id in (?)", @positions.map(&:id)).destroy_all
        @positions.update_all(is_delete: true)
        FlowRelation.remove_relation(@positions)
      end
      @positions.each do |position|
        ChangeRecordWeb.save_record("position_destroy", position).send_notification
      end
      
      render json: {messages: '删除成功'}
    else
      render json: {messages: '请将人员移出后再删除岗位'}, status: 403
    end
  end

  def export_to_xls
    @positions = PositionService.new(params, current_employee).get_positions
    excel = Excel::PositionWriter.new(@positions).write_excel

    send_file(excel.path, filename: excel.filename)
  end

  def export_specification_pdf
    #PositionService需要被废弃
    @positions = PositionService.new(params, current_employee).get_positions.includes(:specification)
    spec_filename = "#{CGI::escape("#{Time.now.to_i}岗位描述书.zip")}"
    spec_path = "#{Rails.root}/public/export/tmp/#{spec_filename}"
    ::Zip::File.open(spec_path, Zip::File::CREATE) do |zipfile|
      @positions.each do |pos|
        spec = pos.specification

        spec = pos.create_specification unless spec
        spec.manual_save_pdf unless File.exist?(spec.pdf_path)
        zipfile.add(spec.pdf_filename.encode("GBK", :invalid => :replace, :undef => :replace, :replace => "?"), spec.pdf_path)
      end
    end

    send_file(spec_path, filename: spec_filename)
  end

  def adjust
    @positions = Position.adjust(params.slice(:department_id, :position_ids))
    @positions.each do |position|
      ChangeRecordWeb.save_record("position_update", position).send_notification
    end
    
    render json: {messages: "岗位调整成功"}
  end

  def employees
    # @employee = Position.find(params[:id]).employee_positions.includes(:employee).where(end_date: nil)
    @employee = Position.find(params[:id]).employee_positions.joins(:employee).where(end_date: nil)
    page = parse_query_params!("employee").values.last
    @employee_positions = set_page_meta(@employee, page)
  end

  def formerleaders
    position = Position.find params[:id]
    return render json: {messages: '该岗位不是领导岗位', employees: []} unless position.leader_position?
    @employee_positions = EmployeePosition.includes(:employee).unscoped.where.not(end_date: nil).where(position_id: position.id)
  end

  private

  def position_params
    safe_params(safe_attributes)
  end

  def safe_attributes
    [
      :name, :budgeted_staffing, :oa_file_no, :channel_id, :schedule_id, :department_id, :category_id,
      :position_nature_id, :post_type, :staffing_remark
    ]
  end
end
