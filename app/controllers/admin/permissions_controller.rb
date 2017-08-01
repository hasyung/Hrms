class Admin::PermissionsController < AdminController
  before_action :set_permission_group, only: [:show, :edit, :destroy, :update]
  before_action :set_permissions,
    only: [:index, :show,:new, :edit, :destroy, :update, :create]

  def index
    FlowRelation.roles.each do |role_name|
      group = PermissionGroup.find_by(name: role_name)
      PermissionGroup.create(name: role_name, permission_ids: [Permission.first.id]) unless group
    end
    @permission_groups = PermissionGroup.all
  end

  def new
    @permission_group = PermissionGroup.new(permission_ids: [])
  end

  def show
  end

  def edit
  end

  def create
    @permission_group = PermissionGroup.new(permission_group_params)
    if @permission_group.save
      render action: 'show'
    else
      render action: 'new'
    end
  end

  def update
    hash = {}

    if FlowRelation.roles.include?(@permission_group.name)
      hash = permission_group_params.delete_if{|k,v|k=='name'}
    else
      hash = permission_group_params
    end
    hash["permission_ids"] = [] if hash["permission_ids"].blank?

    if @permission_group.update(hash)
      render action: 'show'
    else
      render action: 'edit'
    end
  end

  def destroy
    @permission_group = PermissionGroup.find params[:id]

    if FlowRelation.roles.include?(@permission_group.name)
      flash[:error] = "角色权限组不允许删除"
    else
      flash[:notice] = "删除成功"
      @permission_group.destroy
    end

    redirect_to admin_permissions_path
  end

  def permission_assign
    @permission_groups = PermissionGroup.where("name not in (?)", FlowRelation.roles)
    @permissions = Permission.all.order(level: 'asc')
  end

  def grant_permission
    @employee = Employee.unscoped.where(id: params[:employee_id]).first

    if @employee
      @permissions = Permission.where(id: params[:permission_ids])
      @employee.update(bit_value: 0)
      @permissions.each{|permission| permission.grant_permission(@employee)}
      flash[:notice] = "权限赋予成功"
    else
      flash[:error] = "员工不存在"
    end

    redirect_to permission_assign_admin_permissions_path
  end


  def flow_relation_assign
    @departments = Department.where.not(serial_number: '000')
      .order(:d1_sort_no, :d2_sort_no, :d3_sort_no)

    @flow_relations = FlowRelation.where(
      role_name: params[:role_name] || "department_hr"
    ).includes(:department)
    a = []

    @flow_relations.each do |item|
      a << item.position_ids
    end

    @positions = Position.where(id: a.flatten.uniq).index_by(&:id)

    @role_name = params[:role_name]
  end

  def flow_relations_show
    @department_root = Department.find(params[:id])
    @departments = @department_root.get_underling_include_self

    positions = []
    @departments.each do |department|
      positions << department.positions if department.positions.present?
    end

    unless positions.present?
      flash[:notice] = "对不起，该部门包括子部门没有岗位，不能设置#{FlowRelation.get_role_name(params[:role_name])}"
      redirect_to :back and return
    end

    @flow_relation = FlowRelation.find_or_create_by!(
      department_id: @department_root.id,
      role_name: params[:role_name],
      desc: "机构[#{@department_root.name}]#{FlowRelation.get_role_name(params[:role_name])}"
    )

    @role_name = params[:role_name]
  end

  def confirm_flow_relation
    @flow_relation = FlowRelation.find flow_relation_params[:id]

    if @flow_relation
      @flow_relation.update(
        id: flow_relation_params[:id],
        position_ids: flow_relation_params[:position_ids]
      )
      flash[:notice] = "权限赋予成功"
    else
      flash[:notice] = "参数错误"
    end

    redirect_to flow_relation_assign_admin_permissions_path(role_name: @flow_relation.role_name)
  end

  def role_menus
    @role_menu = RoleMenu.find_by(role_name: params[:role_name])
    @role_menu = RoleMenu.new(role_name: params[:role_name]) if @role_menu.blank?
  end

  def create_role_menu
    @role_menu = RoleMenu.new(role_name: params[:role_name], menus: reset_menus)

    if @role_menu.save
      flash[:notice] = "菜单设置成功"
    else
      flash[:notice] = "参数错误"
    end
    redirect_to role_menus_admin_permissions_path(role_name: params[:role_name])
  end

  def edit_role_menu
    @role_menu = RoleMenu.find_by(role_name: params[:role_name])

    if @role_menu.update(menus: reset_menus)
      flash[:notice] = "菜单设置成功"
    else
      flash[:notice] = "参数错误"
    end
    redirect_to role_menus_admin_permissions_path(role_name: params[:role_name])
  end

  private
  def set_permission_group
    @permission_group = PermissionGroup.find params[:id]
  end

  def set_permissions
    @permissions = Permission.all.order(level: 'asc')
  end

  def permission_group_params
    params.require(:permission_group).permit(:name, :permission_ids => [])
  end

  def sys_permission_group_params
    params.require(:permission_group).permit(:permission_ids => [])
  end

  def flow_relation_params
    params.require(:flow_relation).permit(:id, :position_ids => [])
  end

  def reset_menus
    menus = {}
    if params[:menus].present?
      params[:menus][:keys].each do |key|
        menus[key] = params[:menus][:values].to_a & RoleMenu::MENU_CONFIG[key]
      end
    end
    menus
  end
end
