class Api::DepartmentsController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register, only: [:index]
  skip_before_action :check_permission, only: [:index]

  def create
    @department = Department.new(department_params)
    #@department.set_sort_no

    if @department.valid?
      action = Action.create(action_params(department_params.merge(@department.build_params)))
      @department = Department.new(action.data)
      @department.status = "create_inactive"

      render template: '/api/departments/show'
    else
      render json: {messages: @department.errors.values.flatten.join(",")}, status: 400
    end
  end

  def update
    @department = Department.find_with_id(params[:id])
    @department.assign_attributes(department_params)

    if @department.valid?
      Action.create(action_params(department_params.merge("id" => params[:id])))
      @department.status = 'update_inactive'

      render template: '/api/departments/show'
    else
      render json: {messages: @department.errors.values.flatten.join(",")}, status: 400
    end
  end

  def index
    if params[:edit_mode] == "true"
      @departments = Action.batch_execute(Department.includes(:grade, :nature).true_virtual, Action.all.to_a)
    else
      @departments = Department.includes(:grade, :nature).true_virtual.order(:d1_sort_no, :d2_sort_no, :d3_sort_no)
      @departments = @departments.where(grade_id: params[:grade_id]) if params[:grade_id]
    end
  end

  def show
    @department = Department.find(params[:id])
  end

  def destroy
    @department = Department.find_with_id(params[:id])

    if @department.can_destroy?
      Action.create(action_params({"id" => params[:id], "name" => @department.name, "serial_number" => @department.serial_number}))
      render json: {messages: "机构删除成功"}
    else
      render json: {messages: "删除前确保没有子机构，同时该机构下岗位要为空"}, status: 403
    end
  end

  def active
    dep = Department.find_with_id(params[:department_id])
    change_log = DepartmentChangeLog.new(title: params[:title], oa_file_no: params[:oa_file_no],
                                         dep_name: dep.name, department_id: params[:department_id],
                                         step_desc: '', employee_id: @current_employee.id)
    if change_log.valid? && Department.active_change!(change_log)
      render json: {messages: "组织机构变动已经生效"}
    else
      render json: {messages: "组织机构变更生效失败"}, status: 400
    end
  end

  def revert
    Department.revert_change!
    render json: {messages: "组织机构变动已经撤销"}
  end

  def change_logs
    @change_logs = DepartmentChangeLog.all.order('created_at DESC')
  end

  def transfer
    @department = Department.find params[:department_id]
    @to_parent = Department.find params[:to_department_id]
    if @to_parent.id == @department.parent_id
      return render json: {messages: "不能划转到本身的父机构！"}, status: 400
    end

    if @department.grade.readable_index < @to_parent.grade.readable_index
      return render json: {messages: "不能划转到职级比自己低的机构！"}, status: 400
    end
    self_departments = Department.where("serial_number like '#{@department.serial_number}%'")
    if self_departments.include?(@to_parent)
      return render json: {messages: "划到机构不可以是划出机构及其子机构！"}, status: 400
    end

    Action.transaction do
      @department.change_transfer @to_parent
      Action.create(action_params(@department.attributes))
      change_childrens_transfer @department if @department.childrens_count > 0
    end
    @department.status = "transfer_inactive"

    render template: "/api/departments/show"
  end

  def export_to_xls
    department = Department.find(params[:department_id])

    Excel::DepartmentWriter.new([department], department.file_path).write_excel
    send_file(department.file_path, filename: department.filename)
  end

  def rewards
    if params[:month].blank? || params[:month].split('-')[0].to_i == 0 || params[:month].split('-')[1].to_i == 0
      render json: {messages: "参数错误"}, status: 400
    else
      departments = Department.where(depth: 2)
      @rewards = departments.inject([]) do |arr, d|
        arr << d.department_salaries.find_or_create_by(month: params[:month], category: 'reward')
      end
    end
  end

  def reward_update
    @reward = DepartmentSalary.find_by(department_id: params[:department_id], month: params[:month])
    unless @reward && @reward.update(reward_params)
      return render json: {messages: "参数错误"}, status: 400
    end
  end

  def update_set_book_no
    @department = Department.find params[:id]

    if @department.update(set_book_no: params[:set_book_no])
      render json: {messages: '修改成功'}
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  private

  def department_params
    safe_params([:name, :parent_id, :grade_id, :nature_id])
  end

  def action_params(data)
    {model: "department", category: "#{action_name}!", data: data.merge("status" => "#{action_name}_inactive").to_hash}
  end

  def change_childrens_transfer dep
    dep.childrens.each do |c|
      next if Action.where("category = 'transfer!' and data like '%\nid: #{c.id}\n%'").present?
      c.change_transfer dep
      Action.create(action_params(c.attributes))
      change_childrens_transfer c if c.childrens_count > 0
    end
  end

  def reward_params
    params.permit(
      :flight_bonus, :service_bonus, :airline_security_bonus, :composite_bonus,
      :insurance_proxy, :cabin_grow_up, :full_sale_promotion, :article_fee,
      :all_right_fly, :year_composite_bonus, :move_perfect, :security_special,
      :dep_security_undertake, :fly_star, :year_all_right_fly,
      :passenger_quarter_fee, :freight_quality_fee, :earnings_fee,
      :brand_quality_fee
    )
  end
end
