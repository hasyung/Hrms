class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :check_action_register
  skip_before_action :check_permission

  def index
    if current_employee
      @employee = current_employee
      @employee_positions = current_employee.employee_positions
      @departments = Department.includes(:grade, :nature)

      @resources = {}
      @type = Setting.enum_type

      Setting.enum_permit.each do |key, value|
        result = eval(value)
        @resources[key] = []
        result.each do |item|
          @resources[key] << {id: item.id, label: item.display_name}
        end
      end

      @roles = current_employee.get_my_roles

      @roles_menu_config = RoleMenu.get_menus_by_roles(@roles)

      @salaries = Salary.all
      @salary_setting = @salaries.inject({}){|hash, salary| hash.merge!({salary.category + '_setting' => salary.form_data})}

      @messages = Flow.get_messages_count_by_employee(@employee)

      checker_name = ['人力资源部总经理','副总经理（人事、劳动关系、招飞）','副总经理（培训、员工服务）']
      @report_checker = {}

      checker_name.each do |item|
        @report_checker[item] = Position.find_by(name: item).try(:id)
      end

      render template: 'home/index', layout: false
    else
      redirect_to '/sessions/new'
    end
  end

  def metadata
    if current_employee
      @employee = current_employee
      @employee_positions = current_employee.employee_positions
      @emp_languages = current_employee.languages
      @departments = Department.includes(:grade, :nature)

      @resources = {}
      @type = Setting.enum_type

      Setting.enum_permit.each do |key, value|
        result = eval(value)
        @resources[key] = []
        result.each do |item|
          @resources[key] << {id: item.id, label: item.display_name}
        end
      end

      @roles = current_employee.get_my_roles

      @roles_menu_config = RoleMenu.get_menus_by_roles(@roles)

      @salaries = Salary.all
      @salary_setting = @salaries.inject({}){|hash, salary| hash.merge!({salary.category + '_setting' => salary.form_data})}

      @messages = Flow.get_messages_count_by_employee(@employee)

      checker_name = ['人力资源部总经理','副总经理（人事、劳动关系、招飞）','副总经理（培训、员工服务）']
      @report_checker = {}

      checker_name.each do |item|
        @report_checker[item] = Position.find_by(name: item).id
      end

      render template: 'home/metadata', layout: false
    else
      render js: "location.replace(location.origin + '/sessions/new/');"
    end
  end
end
